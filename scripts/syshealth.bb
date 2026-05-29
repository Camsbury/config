#!/usr/bin/env bb
;; syshealth.bb — PSI-triggered system-contention snapshotter (babashka).
;;
;; Sits in a loop watching CPU / memory / IO *pressure* (PSI = time tasks spend
;; STALLED waiting for a resource, distinct from utilization). When stall crosses
;; a threshold AND persists past MINDUR it prints a snapshot that (a) names the
;; resource, (b) gives a plain-language VERDICT, (c) lists the processes responsible
;; — sourced PER RESOURCE: CPU -> top %CPU; MEMORY -> top RES/%MEM; IO -> D-state
;; tasks (the ones actually blocked, which a %CPU sort misses).
;;
;; Tracks two PSI flavors: `some` (>=1 task stalled — the trigger) and, for memory
;; and io, `full` (ALL non-idle tasks stalled — the genuine system-wide lockup).
;; CPU has no meaningful `full` (something is always runnable), so it isn't tracked.
;;
;; Output discipline: one detailed snapshot when an episode STARTS *and has persisted
;; MINDUR seconds* (shorter blips are dropped silently — that's the noise filter),
;; another every RESNAP seconds if it persists, and a one-line recovery summary
;; (duration + some/full peaks) when it clears. The per-second ticker lives on stderr;
;; snapshots on stdout — so `| tee -a spikes.log` logs the snapshots, not the ticker.
;;
;; Usage:
;;   ./syshealth.bb                                  ; 30% some, 1s sample, 3s debounce, resnap 30s
;;   THRESH=20 WINDOW=1 MINDUR=5 RESNAP=15 ./syshealth.bb | tee -a spikes.log
;;
;; Requires kernel PSI (/proc/pressure). No root needed to READ; root only to NAME
;; offenders across other users.

(ns syshealth
  (:require [clojure.string :as str]
            [babashka.process :refer [shell]]))

;; ---- env parsing (validated, never throws at load) ------------------------
(defn- env-long
  "parse-long an env var into [lo,hi]; warn+fall-back on garbage, warn+clamp on
   out-of-range. Stops `THRESH=foo` dying with a stack trace and `WINDOW=0` spinning."
  [name dflt lo hi]
  (let [raw (System/getenv name)
        v   (when raw (try (parse-long (str/trim raw)) (catch Exception _ nil)))]
    (cond
      (nil? raw) dflt
      (nil? v)   (do (binding [*out* *err*]
                       (println (format "WARN %s=%s not an integer; using %d" name raw dflt)))
                     dflt)
      (or (< v lo) (> v hi))
      (do (binding [*out* *err*]
            (println (format "WARN %s=%d out of [%d,%d]; clamping" name v lo hi)))
          (min hi (max lo v)))
      :else v)))

;; ---- config (env-overridable) ---------------------------------------------
(def thresh (env-long "THRESH" 30 1 100))      ; % some-stall that counts as a spike
(def window (env-long "WINDOW" 1  1 3600))     ; seconds between samples (>=1: no spin)
(def mindur (env-long "MINDUR" 3  0 3600))     ; episode must persist this many SECONDS before 1st snapshot (0 = fire now)
(def resnap (env-long "RESNAP" 30 1 86400))    ; re-snapshot a SUSTAINED spike every N s
(def ncpu   (.availableProcessors (Runtime/getRuntime)))           ; core count, for oversubscription ratio
(def minsamples (max 1 (long (Math/ceil (/ (double mindur) (max 1 window))))))  ; debounce in samples

;; ---- /proc reading --------------------------------------------------------
;; bb's `slurp` throws EINVAL on /proc/pressure/* — those are poll-backed special
;; files that only honor a plain sequential read, which is what `cat` does. So we
;; try slurp first (fine for /proc/vmstat etc.) and fall back to cat for the rest.
(defn slurp-proc [path]
  (let [via (try (slurp path) (catch Exception _ nil))]
    (if (and via (not (str/blank? via)))
      via
      (try (let [{:keys [out exit]} (shell {:out :string :err :string :continue true} "cat" path)]
             (when (and (zero? exit) (not (str/blank? out))) out))
           (catch Exception _ nil)))))

(defn psi-total
  "Accumulated stall microseconds for resource (cpu|memory|io), kind (some|full).
   `some` = time >=1 task was stalled; `full` = time ALL non-idle tasks were.
   Returns nil if the line is absent (e.g. cpu has no real `full`)."
  [resource kind]
  (when-let [s (slurp-proc (str "/proc/pressure/" resource))]
    (some (fn [line]
            (when (str/starts-with? line kind)
              (some-> (re-find #"total=(\d+)" line) second parse-long)))
          (str/split-lines s))))

(defn vmstat-map []
  (when-let [s (slurp-proc "/proc/vmstat")]
    (into {} (keep (fn [line]
                     (let [[k v] (str/split line #"\s+")]
                       (when (and k v) [k (parse-long v)])))
                   (str/split-lines s)))))

(defn vm-sum
  "Sum every vmstat counter whose key starts with `prefix` (robust to per-zone
   names like allocstall_normal / allocstall_dma32)."
  [vm prefix]
  (reduce-kv (fn [acc k v] (if (str/starts-with? k prefix) (+ acc v) acc)) 0 vm))

(defn meminfo []
  (when-let [s (slurp-proc "/proc/meminfo")]
    (into {} (keep (fn [line]                        ; "MemTotal:   197132288 kB"
                     (let [[k v] (str/split line #":?\s+")]
                       (when (and k v) [k (parse-long v)])))   ; value in kB
                   (str/split-lines s)))))

(defn proc-counts []
  (let [s (or (slurp-proc "/proc/stat") "")
        g (fn [key] (or (some-> (re-find (re-pattern (str key " (\\d+)")) s) second parse-long) 0))]
    {:running (g "procs_running") :blocked (g "procs_blocked")}))

(defn loadavg []
  (->> (str/split (or (slurp-proc "/proc/loadavg") "") #"\s+") (take 3) (str/join " ")))

;; ---- sampling -------------------------------------------------------------
;; A sample = cumulative counters + a MONOTONIC timestamp. Stall% is always
;; computed against the *real* elapsed time between two samples, never the nominal
;; window — a slow snapshot or starved scheduler can stretch the real interval past
;; WINDOW, and dividing by a fixed window produced bogus >100% numbers earlier.
(defn sample []
  (let [vm   (vmstat-map)
        stat (or (slurp-proc "/proc/stat") "")]
    {:t       (System/nanoTime)
     :cpu     (psi-total "cpu" "some")          ; cpu `full` intentionally not read (degenerate, ~always 0)
     :mem     (psi-total "memory" "some")
     :io      (psi-total "io" "some")
     :memfull (psi-total "memory" "full")
     :iofull  (psi-total "io" "full")
     :alloc   (vm-sum vm "allocstall")
     :dscan   (vm-sum vm "pgscan_direct")
     :compact (vm-sum vm "compact_stall")
     :thp     (vm-sum vm "thp_fault_alloc")
     :majf    (vm-sum vm "pgmajfault")
     :pswpin  (get vm "pswpin" 0)
     :pswpout (get vm "pswpout" 0)
     :oomk    (get vm "oom_kill" 0)
     :ctxt    (some-> (re-find #"ctxt (\d+)" stat) second parse-long)}))

(defn stall%
  "Stall % for counter k between two samples, over their REAL elapsed time.
   Rounds (not truncates) so a 29.6% stall reads 30, not 29."
  [k prev now]
  (let [elapsed-us (/ (double (- (:t now) (:t prev))) 1000.0)    ; ns -> us
        d          (- (or (k now) 0) (or (k prev) 0))]
    (if (pos? elapsed-us) (long (Math/round (/ (* 100.0 d) elapsed-us))) 0)))

(defn deltas [prev now]
  (into {} (for [k [:alloc :dscan :compact :thp :majf :pswpin :pswpout :oomk]]
             [k (- (or (k now) 0) (or (k prev) 0))])))

(defn ctxt-rate
  "Context switches per real second between two samples."
  [prev now]
  (let [secs (/ (double (- (:t now) (:t prev))) 1.0e9)]
    (if (and (:ctxt now) (:ctxt prev) (pos? secs))
      (long (/ (- (:ctxt now) (:ctxt prev)) secs)) 0)))

(defn runnable-burst
  "Average + peak procs_running over a short burst. One instantaneous read is too
   noisy to anchor an oversubscription verdict on; n reads dt-ms apart smooth jitter."
  [n dt-ms]
  (loop [i n, acc 0, pk 0]
    (if (zero? i)
      {:avg (long (Math/round (/ (double acc) (max 1 n)))) :peak pk}
      (let [r (:running (proc-counts))]
        (when (pos? (dec i)) (Thread/sleep dt-ms))
        (recur (dec i) (+ acc r) (max pk r))))))

;; ---- self-exclusion: never flag the watcher's own footprint ---------------
;; We run at Nice=-10 (to stay schedulable on a pegged box), and spawn top/cat.
;; Exclude: the bb process; any LIVE helper sharing our service cgroup; and the
;; ephemeral top/cat already exited by parse time (unreadable cgroup -> comm fallback).
;; Plain slurp (ordinary /proc files, no cat fallback -> a vanished pid just -> nil).
(def ^:private own-pid
  (delay (try (-> (slurp "/proc/self/stat") (str/split #"\s+") first) (catch Exception _ nil))))
(def ^:private own-cgroup
  (delay (try (str/trim (slurp "/proc/self/cgroup")) (catch Exception _ nil))))
(defn- mine? [pid comm]
  (or (= pid @own-pid)
      (let [cg (try (str/trim (slurp (str "/proc/" pid "/cgroup"))) (catch Exception _ nil))]
        (if cg (= cg @own-cgroup) (contains? #{"bb" "top" "cat"} comm)))))

;; ---- offender classification ----------------------------------------------
;; The general fix for "a benign background task on an idle box reads as a
;; system-wide lockup." PSI magnitude alone can't tell a real freeze from one
;; low-priority task doing sustained IO/mem while nothing else runs. The honest
;; discriminator is CONTENTION BREADTH (how many tasks were stalled / how deep the
;; queue), which `verdict` now uses for severity. These tags are explanatory only
;; — never used to drop a proc — so the whole family reads correctly: ext4lazyinit,
;; md/RAID resync, btrfs/zfs scrub, kswapd/kcompactd reclaim, fstrim, updatedb/
;; mlocate, nix GC, restic/borg/rsync backups, jbd2 commits, kworker flush, etc.
(def ^:private bg-name-re
  #"(?i)ext4lazyinit|jbd2|kworker|kswapd|kcompactd|khugepaged|ksoftirqd|_resync|_recovery|raid|scrub|btrfs|txg_sync|fstrim|discard|updatedb|m?locate|nix-store|nix-daemon|restic|borg|duplicity|rsync|rclone|e2scrub|smartd|fsck|fwupd|packagekit|snapper")
(defn- kthread?
  "Kernel threads have an empty /proc/<pid>/cmdline (no userspace argv)."
  [pid]
  (try (str/blank? (slurp (str "/proc/" pid "/cmdline"))) (catch Exception _ false)))
(defn- classify
  "Tag a proc (needs :pid :comm) with :kthread and :bg (kthread OR recognized
   maintenance task). Annotation only."
  [p]
  (let [kt (kthread? (:pid p))]
    (assoc p :kthread kt
             :bg (or kt (boolean (and (:comm p) (re-find bg-name-re (:comm p))))))))
(defn- bg-tag [p] (cond (:kthread p) " [kthread]" (:bg p) " [bg]" :else ""))

;; ---- process tables (columns resolved by header, never by position) -------
(defn- top-rows
  "Run `top` with `args`; return the chosen iteration's process rows as maps keyed
   by column header name. `iter` = which PID-header block (0-based); `top -bn2`
   emits two and only the SECOND reflects the -d delta."
  [args iter]
  (try
    (let [out      (:out (apply shell {:out :string :err :string :continue true} "top" args))
          lines    (vec (str/split-lines out))
          hdr-idxs (vec (keep-indexed (fn [i l] (when (re-find #"^\s*PID" l) i)) lines))
          start    (get hdr-idxs iter)]
      (when start
        (let [cols (->> (str/split (str/trim (nth lines start)) #"\s+")
                        (map-indexed (fn [i c] [c i])) (into {}))
              end  (or (get hdr-idxs (inc iter)) (count lines))]
          (->> (subvec lines (inc start) end)
               (filter #(re-find #"^\s*\d+" %))
               (mapv (fn [l]
                       (let [f (str/split (str/trim l) #"\s+")]
                         (reduce-kv (fn [m name i] (assoc m name (get f i))) {} cols))))))))
    (catch Exception _ nil)))

(defn top-cpu
  "Top-n by recent %CPU (second top iteration). Carries PR so realtime tasks read
   `rt` instead of being conflated with an NI of '-'."
  [n]
  (->> (top-rows ["-bn2" "-d" "0.3" "-o" "%CPU" "-w" "512"] 1)
       (take n)
       (mapv (fn [r] {:pid  (r "PID")
                      :pr   (r "PR")
                      :ni   (some-> (r "NI") parse-long)
                      :cpu  (or (some-> (r "%CPU") parse-double) 0.0)
                      :res  (r "RES")
                      :comm (r "COMMAND")}))))

(defn top-mem
  "Top-n by %MEM (single iteration — RES/%MEM are instantaneous)."
  [n]
  (->> (top-rows ["-bn1" "-o" "%MEM" "-w" "512"] 0)
       (take n)
       (mapv (fn [r] {:pid  (r "PID")
                      :mem  (or (some-> (r "%MEM") parse-double) 0.0)
                      :res  (r "RES")
                      :comm (r "COMMAND")}))))

(defn blocked-procs
  "PIDs in uninterruptible sleep (state D) — tasks actually stalled on io/reclaim,
   which a %CPU sort misses (they burn no CPU while blocked)."
  [n]
  (->> (try (->> (.listFiles (java.io.File. "/proc"))
                 (filter #(re-matches #"\d+" (.getName %))))
            (catch Exception _ nil))
       (keep (fn [d]
               (let [pid  (.getName d)
                     stat (slurp-proc (str "/proc/" pid "/stat"))]
                 (when stat
                   (let [op    (str/index-of stat "(")
                         rp    (str/last-index-of stat ")")
                         state (when rp (-> stat (subs (+ rp 2)) (str/split #"\s+") first))
                         comm  (when (and op rp (< op rp)) (subs stat (inc op) rp))]
                     (when (= state "D")
                       {:pid pid :comm comm :state state}))))))
       (take n)
       vec))

;; ---- verdict --------------------------------------------------------------
;; `dominant` keeps a fixed cpu>mem>io tie-break for routing the proc list; a real
;; tie is surfaced by `verdict` (co-elevated line), not swallowed.
(defn dominant [cpu mem io]
  (let [m (max cpu mem io)]
    (cond (< m thresh) nil, (= m cpu) :cpu, (= m mem) :mem, :else :io)))

(defn verdict
  "Plain-language diagnosis. Severity is PSI magnitude SCALED BY contention breadth
   (tasks blocked + run-queue depth), never magnitude alone: a single low-priority
   task doing sustained IO/mem on an idle box pins `full` high without anything being
   locked up. Strong 'system-wide lockup' wording is reserved for a genuinely broad
   queue; shallow episodes are called localized, and if the only stalled tasks are
   background/maintenance (:bg) that's stated outright. Same principle the CPU branch
   already uses: 'oversubscribed' only when runnable actually exceeds cores."
  [m runnable procs dom]
  (let [{:keys [cpu mem io memf iof pswp? oomk blocked load1]} m
        elevated (->> [[:cpu cpu] [:mem mem] [:io io]]
                      (filter #(>= (second %) thresh)) (mapv (comp name first)))
        ;; severity = magnitude SCALED BY breadth (the general fix)
        broad?   (or (>= (or blocked 0) 3) (> runnable ncpu))
        bg-only? (and (seq procs) (every? :bg procs))
        names    (->> procs (keep :comm) distinct (take 3) (str/join ", "))
        co (when (> (count elevated) 1)
             [(format "Co-elevated: %s all >=%d%% (some) — fix the dominant resource first, then recheck."
                      (str/join "+" elevated) thresh)])
        body (case dom
               :cpu (let [top    (first procs)
                          top2   (or (:cpu (second procs)) 0.0)
                          ratio  (/ (double runnable) (max 1 ncpu))
                          lratio (/ (double (or load1 0.0)) (max 1 ncpu))
                          dom1?  (and top (>= (or (:cpu top) 0.0) 100.0) (>= (or (:cpu top) 0.0) (* 3.0 top2)))
                          queue  (cond
                                   (> ratio 2.0) (format "Queue %.1fx (%d/%d runnable), load1 %.0f ≈ %.1fx sustained — oversubscribed, expect visible latency." ratio runnable ncpu (or load1 0.0) lratio)
                                   (> ratio 1.0) (format "Queue %.1fx (%d/%d runnable), load1 %.0f ≈ %.1fx sustained — mildly over; tolerable unless it climbs." ratio runnable ncpu (or load1 0.0) lratio)
                                   :else         (format "Queue %.1fx (%d/%d runnable) — NOT oversubscribed; high cpu-some + shallow queue ⇒ check ctxt/s for a switch storm." ratio runnable ncpu))]
                      (if (and top (:comm top))
                        [(if dom1?
                           (format "%s (pid %s) ≈ %.1f cores dominates — the spike is this process (nice %s)."
                                   (:comm top) (:pid top) (/ (:cpu top) 100.0)
                                   (cond (= "rt" (:pr top)) "rt" (:ni top) (str (:ni top)) :else "?"))
                           (format "Led by %s (pid %s) ≈ %.1f cores, plus others (see PROC)."
                                   (:comm top) (:pid top) (/ (:cpu top) 100.0)))
                         queue]
                        [queue]))
               :mem (cond-> ["MEMORY pressure: reclaim/compaction stalling tasks — nice CANNOT help. Cap the offender (MemoryHigh/Max) or cut allocation. Procs below sorted by RES/%MEM."]
                      (>= memf thresh)
                      (conj (cond
                              broad?   (format "FULL stall %d%% with a deep queue (%d blocked, %d/%d runnable) — broad, user-visible memory lockup." memf (or blocked 0) runnable ncpu)
                              bg-only? (format "mem-full %d%% but the queue is shallow (%d blocked, %d/%d runnable) and the only pressure is background/maintenance (%s) — expected, not a freeze." memf (or blocked 0) runnable ncpu names)
                              :else    (format "mem-full %d%% on a shallow queue (%d blocked, %d/%d runnable) — localized stall, not system-wide." memf (or blocked 0) runnable ncpu)))
                      pswp?
                      (conj "Actively swapping (swapin/swapout nonzero) — thrashing; latency cliffs until RSS drops.")
                      (pos? oomk)
                      (conj (format "⚠ OOM killer fired x%d this interval — kernel reaped task(s) to recover." oomk)))
               :io  (cond-> ["IO pressure: tasks blocked on disk — reach for io.max / ionice, not nice. Procs below are in D-state (the ones actually stalled)."]
                      (>= iof thresh)
                      (conj (cond
                              broad?   (format "FULL stall %d%% with %d tasks blocked (%d/%d runnable) — broad, likely user-visible IO lockup." iof (or blocked 0) runnable ncpu)
                              bg-only? (format "io-full %d%% but only background/maintenance tasks are stalled (%s) on a shallow queue (%d blocked, %d/%d runnable) — expected device pressure on an idle box, NOT a freeze." iof names (or blocked 0) runnable ncpu)
                              :else    (format "io-full %d%% but only %d task(s) blocked on a shallow queue (%d/%d runnable) — localized stall, not system-wide." iof (or blocked 0) runnable ncpu))))
               ["(spike cleared between detection and snapshot)"])]
    (into (vec co) body)))

;; ---- formatting -----------------------------------------------------------
(defn now-str [pat]
  (.format (java.time.LocalDateTime/now)
           (java.time.format.DateTimeFormatter/ofPattern pat)))

(defn mem-line [mi]
  (let [g      (fn [k] (/ (double (or (get mi k) 0)) 1048576.0))
        memtot (max 1 (or (get mi "MemTotal") 1))]
    (format "MEM        avail=%.1fG / %.1fG   swapfree=%.1fG   committed=%.1fG (%.0f%% RAM)   dirty+wb=%.0fM"
            (g "MemAvailable") (g "MemTotal") (g "SwapFree") (g "Committed_AS")
            (* 100.0 (/ (double (or (get mi "Committed_AS") 0)) memtot))
            (/ (double (+ (or (get mi "Dirty") 0) (or (get mi "Writeback") 0))) 1024.0))))

(defn- material-procs
  "Trim offenders to contributors that matter, collapsing the negligible tail to a
   single counted line. cpu/mem keep procs >= 10% of the leader's value (procs come
   sorted desc); io keeps all (a blocked task is signal regardless of magnitude).
   Returns [shown collapse-note-or-nil]."
  [dom procs]
  (if (or (= dom :io) (<= (count procs) 1))
    [procs nil]
    (let [k     (if (= dom :mem) :mem :cpu)
          lead  (apply max 0.0 (map #(or (k %) 0.0) procs))
          cut   (* 0.10 lead)
          shown (let [s (vec (take-while #(>= (or (k %) 0.0) cut) procs))]
                  (if (seq s) s (vec (take 1 procs))))
          tail  (subvec (vec procs) (count shown))]
      [shown
       (when (seq tail)
         (let [maxr  (apply max 0.0 (map #(or (k %) 0.0) tail))
               names (->> tail (keep :comm) (map #(first (str/split % #"[/:]"))) distinct (take 4) (str/join "/"))]
           (format "(+%d more ≤%.0f%% %s — %s, negligible)"
                   (count tail) maxr (if (= k :cpu) "CPU" "MEM") names)))])))

(defn print-procs
  "Resource-appropriate offender table, trimmed to material contributors. cpu ->
   %CPU/nice/res, mem -> %MEM/res, io -> D-state/pid."
  [dom procs]
  (let [[shown note] (material-procs dom procs)]
    (case dom
      :mem (do (println "PROC          %MEM         res  command")
               (doseq [p shown]
                 (println (format "             %9.1f%%  %10s res  %s"
                                  (:mem p) (or (:res p) "?") (str (or (:comm p) "?") (bg-tag p))))))
      :io  (do (println "PROC          state  pid      command   (D = blocked on io/reclaim)")
               (if (seq shown)
                 (doseq [p shown]
                   (println (format "             %-5s  %-7s  %s"
                                    (:state p) (:pid p) (str (or (:comm p) "?") (bg-tag p)))))
                 (println "             (no tasks in D-state at this instant)")))
      (do (println "PROC          %CPU      nice         res  command")
          (doseq [p shown]
            (println (format "             %9.1f%%  ni %-4s  %10s res  %s"
                             (:cpu p)
                             (cond (= "rt" (:pr p)) "rt" (:ni p) (str (:ni p)) :else "?")
                             (or (:res p) "?") (str (or (:comm p) "?") (bg-tag p)))))))
    (when note (println (str "             " note)))))

(defn snapshot [tag prev now]
  (let [cpu  (stall% :cpu prev now)
        mem  (stall% :mem prev now)
        io   (stall% :io prev now)
        memf (stall% :memfull prev now)
        iof  (stall% :iofull prev now)
        dom  (dominant cpu mem io)
        d    (deltas prev now)
        ctxt (ctxt-rate prev now)
        pswp? (or (pos? (:pswpin d)) (pos? (:pswpout d)))
        oomk (:oomk d)
        mi   (meminfo)
        {:keys [running blocked]} (proc-counts)
        rb   (runnable-burst 5 40)
        load (loadavg)
        load1 (some-> load (str/split #"\s+") first parse-double)
        ;; fetch extra, drop our own footprint, then keep 12 real offenders
        procs (->> (case dom :mem (top-mem 16) :io (blocked-procs 16) (top-cpu 16))
                   (remove (fn [p] (mine? (:pid p) (:comm p))))
                   (take 12) (mapv classify))
        mtr  {:cpu cpu :mem mem :io io :memf memf :iof iof :pswp? pswp? :oomk oomk :blocked blocked :load1 load1}
        ;; show only nonzero reclaim counters; omit the line entirely when all clear
        rc   (->> [["allocstall" (:alloc d)] ["pgscan_direct" (:dscan d)] ["compact_stall" (:compact d)]
                   ["swapin" (:pswpin d)] ["swapout" (:pswpout d)]]
                  (filter #(pos? (or (second %) 0)))
                  (map (fn [[k v]] (format "%s=%d" k v))))]
    (println (format "==== %-13s %s  %s ===="
                     tag (now-str "yyyy-MM-dd HH:mm:ss")
                     (if dom (format "[%s %d%% some]" (name dom) (case dom :cpu cpu :mem mem :io io 0)) "")))
    (doseq [l (verdict mtr (:avg rb) procs dom)] (println (str "VERDICT    " l)))
    (println (format "RESOURCE   some: cpu=%d%% mem=%d%% io=%d%%   full: mem=%d%% io=%d%%   (>=%d%% some = spike; full = ALL tasks stalled)"
                     cpu mem io memf iof thresh))
    (println (format "QUEUE      runnable inst=%d avg=%d peak=%d / %d cores   blocked(D)=%d   ctxt=%d/s   load=%s"
                     running (:avg rb) (:peak rb) ncpu blocked ctxt load))
    (println (mem-line mi))
    (when (seq rc)
      (println (str "RECLAIM Δ  " (str/join "  " rc) "   ⇐ memory pressure")))
    (when (pos? oomk)
      (println (format "OOM     ⚠  oom_kill=%d this interval — kernel killed task(s)" oomk)))
    (print-procs dom procs)
    (println)
    (flush)))

(defn summary [ep]
  (let [dur  (/ (double (- (System/nanoTime) (:start ep))) 1.0e9)
        dims (->> [["cpu" (:pcpu ep)] ["mem" (:pmem ep)] ["io" (:pio ep)]
                   ["mem-full" (:pmemf ep)] ["io-full" (:piof ep)]]
                  (filter #(>= (or (second %) 0) 5))      ; drop dimensions that stayed negligible
                  (map (fn [[k v]] (format "%s %d%%" k v))))]
    (println (format "---- recovered after %.0fs   peaks: %s   runnable %d ----\n"
                     dur (if (seq dims) (str/join ", " dims) "all <5%") (:prun ep)))
    (flush)))

(defn ticker [cpu mem io run phase]
  (binding [*out* *err*]
    (printf "\r[%s] cpu %3d%% mem %3d%% io %3d%%  runnable=%-4d %s   "
            (now-str "HH:mm:ss") cpu mem io run
            (case phase :active "◀ SPIKING " :pending "◀ watching" "          "))
    (flush)))

(defn legend []
  (binding [*out* *err*]
    (println "syshealth — PSI contention watcher")
    (println (format "  %d%% some-stall · %ds sample · debounce %ds (%d samples) · resnap %ds · %d cores · Ctrl-C to stop"
                     thresh window mindur minsamples resnap ncpu))
    (println "  one snapshot per CONFIRMED episode (stdout); live ticker here (stderr). Read top-down:")
    (println "    VERDICT  the diagnosis in words — read this first")
    (println "    RESOURCE some=>=1 task stalled (trigger) · full=ALL tasks stalled (the real lockup signal)")
    (println "    QUEUE    runnable.avg ≫ cores ⇒ oversubscribed; high ctxt/s w/o oversub ⇒ switch storm; blocked(D) ⇒ io/reclaim")
    (println "    RECLAIM  shown only when nonzero: allocstall/pgscan_direct/compact_stall/swap ⇒ memory pressure; OOM line ⇒ kernel killed a task")
    (println "    PROC     material offenders only (>=10% of the leader); rest collapsed to a count. cpu=%CPU · mem=RES/%MEM · io=D-state ([kthread]/[bg]=kernel/maintenance)")
    (println)
    (flush)))

;; ---- main: edge-triggered episode tracking with debounce ------------------
;; st phases: :calm -> :pending (counting consecutive spiking samples) -> :active.
;; A spike that clears before MINDUR never reaches :active, so no snapshot is emitted.
(defn -main []
  (when-not (slurp-proc "/proc/pressure/cpu")
    (binding [*out* *err*] (println "FATAL: cannot read /proc/pressure/cpu (kernel PSI). Aborting."))
    (System/exit 1))
  (legend)
  (loop [prev (sample), st {:phase :calm}]
    (Thread/sleep (* window 1000))
    (let [now  (sample)
          cpu  (stall% :cpu prev now), mem (stall% :mem prev now), io (stall% :io prev now)
          memf (stall% :memfull prev now), iof (stall% :iofull prev now)
          run  (:running (proc-counts))
          spiking? (or (>= cpu thresh) (>= mem thresh) (>= io thresh))
          bump (fn [s] (-> s (update :pcpu max cpu) (update :pmem max mem) (update :pio max io)
                           (update :pmemf max memf) (update :piof max iof) (update :prun max run)))
          fresh {:phase :pending :n 1 :start (System/nanoTime)
                 :pcpu 0 :pmem 0 :pio 0 :pmemf 0 :piof 0 :prun 0}]
      (ticker cpu mem io run (:phase st))
      (case (:phase st)
        :calm
        (if spiking?
          (let [st0 (bump fresh)]
            (if (>= 1 minsamples)                         ; no debounce -> fire immediately
              (do (binding [*out* *err*] (println))
                  (snapshot "SPIKE START" prev now)
                  (recur now (assoc st0 :phase :active :last (System/nanoTime))))
              (recur now st0)))
          (recur now {:phase :calm}))

        :pending
        (cond
          (not spiking?) (recur now {:phase :calm})       ; sub-MINDUR blip — drop silently
          (>= (inc (:n st)) minsamples)                   ; confirmed: emit first snapshot
          (do (binding [*out* *err*] (println))
              (snapshot "SPIKE START" prev now)
              (recur now (-> (bump st) (assoc :phase :active :last (System/nanoTime)))))
          :else (recur now (-> (bump st) (update :n inc))))

        :active
        (let [st* (bump st)]
          (cond
            (not spiking?)
            (do (binding [*out* *err*] (println))
                (summary st*)
                (recur now {:phase :calm}))
            (>= (/ (double (- (System/nanoTime) (:last st*))) 1.0e9) resnap)
            (do (binding [*out* *err*] (println))
                (snapshot "STILL SPIKING" prev now)
                (recur now (assoc st* :last (System/nanoTime))))
            :else (recur now st*)))))))

(-main)

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
  "Plain-language diagnosis. `m` carries some-% (cpu/mem/io), full-% (memf/iof),
   ctxt/s, swap flag, oom count. 'oversubscribed' is used ONLY when runnable > cores
   — PSI `some` can be high with the queue under core count (migration/throttling/
   switch storm), which is not oversubscription. `runnable` is the burst average."
  [m runnable procs dom]
  (let [{:keys [cpu mem io memf iof pswp? oomk]} m
        elevated                                 (->> [[:cpu cpu] [:mem mem] [:io io]]
                                                      (filter #(>= (second %) thresh)) (mapv (comp name first)))
        co                                       (when (> (count elevated) 1)
                                                   [(format "Co-elevated: %s all >=%d%% (some) — fix the dominant resource first, then recheck."
                                                            (str/join "+" elevated) thresh)])
        body                                     (case dom
                                                   :cpu (let [top   (first procs)
                                                              ratio (/ (double runnable) (max 1 ncpu))]
                                                          (cond-> [(if (> ratio 2.0)
                                                                     (format "CPU-bound: %d runnable on %d cores (%.1fx oversubscribed)."
                                                                             runnable ncpu ratio)
                                                                     (format "CPU pressure, run queue NOT oversubscribed: %d runnable on %d cores (%.1fx) — brief/bursty contention; check ctxt/s in QUEUE for a switch storm (lock/futex contention) before blaming raw compute."
                                                                             runnable ncpu ratio))]
                                                            (and top (:comm top))
                                                            (conj (format "Top consumer %s (pid %s) ≈ %.1f cores at nice %s."
                                                                          (:comm top) (:pid top) (/ (:cpu top) 100.0)
                                                                          (cond (= "rt" (:pr top)) "rt" (:ni top) (str (:ni top)) :else "?")))))
                                                   :mem (cond-> ["MEMORY pressure: reclaim/compaction stalling tasks — nice CANNOT help. Cap the offender (MemoryHigh/Max) or cut allocation. Procs below sorted by RES/%MEM."]
                                                          (>= memf thresh)
                                                          (conj (format "FULL stall %d%% — EVERY runnable task blocked on memory at points; this is a real lockup, not a blip." memf))
                                                          pswp?
                                                          (conj "Actively swapping (swapin/swapout nonzero) — thrashing; latency cliffs until RSS drops.")
                                                          (pos? oomk)
                                                          (conj (format "⚠ OOM killer fired x%d this interval — kernel reaped task(s) to recover." oomk)))
                                                   :io  (cond-> ["IO pressure: tasks blocked on disk — reach for io.max / ionice, not nice. Procs below are in D-state (the ones actually stalled)."]
                                                          (>= iof thresh)
                                                          (conj (format "FULL stall %d%% — EVERY runnable task blocked on IO at points; genuine system-wide IO lockup." iof)))
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

(defn print-procs
  "Resource-appropriate offender table: cpu -> %CPU/nice/res, mem -> %MEM/res,
   io -> D-state/pid. nice/res are shown, never alarmed."
  [dom procs]
  (case dom
    :mem (do (println "PROC          %MEM         res  command")
             (doseq [p procs]
               (println (format "             %9.1f%%  %10s res  %s"
                                (:mem p) (or (:res p) "?") (or (:comm p) "?")))))
    :io  (do (println "PROC          state  pid      command   (D = blocked on io/reclaim)")
             (if (seq procs)
               (doseq [p procs]
                 (println (format "             %-5s  %-7s  %s"
                                  (:state p) (:pid p) (or (:comm p) "?"))))
               (println "             (no tasks in D-state at this instant)")))
    (do (println "PROC          %CPU      nice         res  command")
        (doseq [p procs]
          (println (format "             %9.1f%%  ni %-4s  %10s res  %s"
                           (:cpu p)
                           (cond (= "rt" (:pr p)) "rt" (:ni p) (str (:ni p)) :else "?")
                           (or (:res p) "?") (or (:comm p) "?")))))))

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
        ;; fetch extra, drop our own footprint, then keep 12 real offenders
        procs (->> (case dom :mem (top-mem 16) :io (blocked-procs 16) (top-cpu 16))
                   (remove (fn [p] (mine? (:pid p) (:comm p))))
                   (take 12) vec)
        reclaim? (or (pos? (:alloc d)) (pos? (:dscan d)) (pos? (:compact d)) pswp?)
        mtr  {:cpu cpu :mem mem :io io :memf memf :iof iof :pswp? pswp? :oomk oomk}]
    (println (format "==== %-13s %s ====================" tag (now-str "yyyy-MM-dd HH:mm:ss")))
    (doseq [l (verdict mtr (:avg rb) procs dom)] (println (str "VERDICT    " l)))
    (println (format "RESOURCE   some: cpu=%d%% mem=%d%% io=%d%%   full: mem=%d%% io=%d%%   (>=%d%% some = spike; full = ALL tasks stalled)"
                     cpu mem io memf iof thresh))
    (println (format "QUEUE      runnable inst=%d avg=%d peak=%d / %d cores   blocked(D)=%d   ctxt=%d/s   load=%s"
                     running (:avg rb) (:peak rb) ncpu blocked ctxt (loadavg)))
    (println (mem-line mi))
    (println (format "RECLAIM Δ  allocstall=%d  pgscan_direct=%d  compact_stall=%d  swapin=%d  swapout=%d   %s"
                     (:alloc d) (:dscan d) (:compact d) (:pswpin d) (:pswpout d)
                     (if reclaim? "⇐ memory pressure" "(none)")))
    (when (pos? oomk)
      (println (format "OOM     ⚠  oom_kill=%d this interval — kernel killed task(s)" oomk)))
    (println (format "AMBIENT Δ  thp_fault=%d  majflt=%d   (normal VM traffic; NOT a pressure signal)"
                     (:thp d) (:majf d)))
    (print-procs dom procs)
    (println)
    (flush)))

(defn summary [ep]
  (let [dur (/ (double (- (System/nanoTime) (:start ep))) 1.0e9)]
    (println (format "---- recovered after %.0fs   peaks some: cpu=%d%% mem=%d%% io=%d%%   full: mem=%d%% io=%d%%   runnable=%d ----\n"
                     dur (:pcpu ep) (:pmem ep) (:pio ep) (:pmemf ep) (:piof ep) (:prun ep)))
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
    (println "    RECLAIM  allocstall/pgscan_direct/compact_stall/swap nonzero ⇒ memory pressure; OOM line ⇒ kernel killed a task")
    (println "    AMBIENT  thp_fault/majflt — routine VM traffic, ignore for diagnosis")
    (println "    PROC     offenders per resource: cpu=%CPU · mem=RES/%MEM · io=D-state (nice/res shown, not alarmed)")
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

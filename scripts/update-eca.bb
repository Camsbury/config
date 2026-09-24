#!/usr/bin/env bb
;; Update both eca "recipes" together:
;;
;;   1. the eca-emacs CLIENT pin in nix-conf/overlays/emacs.nix
;;      (version + rev + hash), and
;;   2. the eca SERVER version pin `ck/eca-server-version' in
;;      emacs-conf/config/services/eca.el.
;;
;; Client and server are separate repos with independent version numbers;
;; this keeps the pair we run moving together instead of drifting.
;;
;; A new client pin must pass the ECA upstream guard: the
;; `cmacs-eca-upstream-guard' system check, which fails when eca-emacs no
;; longer defines a name that emacs-conf/config/services/eca/upstream.el
;; wraps. The script builds that check against the new pin: the cmacs Emacs
;; package set plus the guard, where normally only the eca package is new,
;; not the whole system. On failure it reports each missing name with
;; similar names from the new eca-emacs source, restores the old client
;; pin, leaves the server pin alone, and exits 1. Fix the adapter, then
;; rerun.
;;
;; nix-conf/system.nix evaluates /etc/nixos/configuration.nix, so the check
;; only proves anything when that file lives in this checkout; the script
;; refuses to run otherwise.
;;
;; It does not rebuild the system or reload Emacs (do those yourself, e.g.
;; nixos-rebuild + M-x ck/latest-loadpath for the client, and let eca
;; re-download the server on next start).
;;
;; Usage:
;;   scripts/update-eca.bb                     # both to latest
;;   scripts/update-eca.bb --client <rev>      # pin client to a commit
;;   scripts/update-eca.bb --server <tag>      # pin server to a release tag
;;   (flags combine; omit either to take that side's latest)

(require '[babashka.fs :as fs]
         '[babashka.http-client :as http]
         '[babashka.process :refer [process shell]]
         '[cheshire.core :as json]
         '[clojure.java.io :as io]
         '[clojure.string :as str])

(def client-repo "editor-code-assistant/eca-emacs")
(def server-repo "editor-code-assistant/eca")

(def repo-root (-> *file* fs/canonicalize fs/parent fs/parent))
(def overlay-file (str (fs/path repo-root "nix-conf/overlays/emacs.nix")))
(def eca-el-file  (str (fs/path repo-root "emacs-conf/config/services/eca.el")))
(def system-file  (str (fs/path repo-root "nix-conf/system.nix")))
(def nixos-config "/etc/nixos/configuration.nix")

(defn assert-system-uses-repo!
  "Exit 1 unless the NixOS configuration that system.nix evaluates lives in
  this checkout; otherwise the guard would check a different tree."
  []
  (let [nix-conf (fs/canonicalize (fs/path repo-root "nix-conf"))
        config   (when (fs/exists? nixos-config)
                   (fs/canonicalize nixos-config))]
    (when-not (and config (fs/starts-with? config nix-conf))
      (println (format "error: %s resolves to %s, not into %s;"
                       nixos-config config nix-conf)
               "the guard would check a different tree.")
      (System/exit 1))))

(defn gh-get [url]
  (-> (http/get url {:headers {"Accept" "application/vnd.github+json"}})
      :body
      (json/parse-string true)))

;;; --- client (eca-emacs) ----------------------------------------------------

(defn client-commit
  "Resolve `ref` to {:sha ... :date ...} (committer date, ISO-8601 UTC:
  what MELPA versions are built from)."
  [ref]
  (let [body (gh-get (format "https://api.github.com/repos/%s/commits/%s"
                             client-repo ref))]
    {:sha (:sha body) :date (get-in body [:commit :committer :date])}))

(defn melpa-version
  "MELPA snapshot version for an ISO-8601 UTC commit date: YYYYMMDD.HHMM with
  the time's leading zeros dropped (it is parsed as a number)."
  [iso-date]
  (let [[date time] (str/split iso-date #"T")
        day  (str/replace date "-" "")
        hhmm (-> time (subs 0 5) (str/replace ":" "") Long/parseLong)]
    (str day "." hhmm)))

(defn prefetch-source
  "Fetch the client source at `sha`. Returns {:hash :store-path}: the SRI
  hash for fetchFromGitHub (same NAR hash as a github: input) and the
  fetched tree."
  [sha]
  (let [{:keys [hash storePath]}
        (-> (shell {:out :string} "nix" "flake" "prefetch" "--json"
                   (format "github:%s/%s" client-repo sha))
            :out (json/parse-string true))]
    {:hash hash :store-path storePath}))

(def client-block-re
  ;; Anchored on `eca =` so the other packages' bindings are never touched.
  #"(?s)(eca =\s+let\s+version = \")[^\"]+(\";\s+rev = \")[^\"]+(\";\s+hash = \")[^\"]+(\";)")

(defn update-client!
  "Rewrite the client pin to `ref` (default HEAD). Returns {:changed?} plus,
  when the pin changed, the :old-block pin text and the new :store-path."
  [ref]
  (let [{:keys [sha date]} (client-commit (or ref "HEAD"))
        version (melpa-version date)
        _       (println (format "client: eca-emacs %s (%s, %s)"
                                 version (subs sha 0 12) date))
        {:keys [hash store-path]} (prefetch-source sha)
        old     (slurp overlay-file)
        n       (count (re-seq client-block-re old))]
    (when (not= 1 n)
      (println (format "error: expected 1 eca block in %s, found %d"
                       overlay-file n))
      (System/exit 1))
    (let [new (str/replace old client-block-re
                           (str "$1" version "$2" sha "$3" hash "$4"))]
      (if (= old new)
        (do (println "  client already up to date")
            {:changed? false})
        (do (spit overlay-file new)
            (println (format (str "  -> %s\n     version %s\n"
                                  "     rev     %s\n     hash    %s")
                             overlay-file version sha hash))
            {:changed?   true
             :old-block  (first (re-find client-block-re old))
             :store-path store-path})))))

(defn restore-client-block!
  "Put `old-block` back as the eca pin. Only that block is replaced, so
  other edits made to the overlay during the guard build survive."
  [old-block]
  (let [text (slurp overlay-file)]
    (spit overlay-file
          (str/replace text client-block-re
                       (java.util.regex.Matcher/quoteReplacement
                        old-block)))))

;;; --- guard (new client pin vs the ECA upstream adapter) -------------------

(defn build-guard
  "Build the guard system check against the pins now on disk, echoing nix's
  log to stderr as it arrives. Returns {:ok? :log}, :log being the lines.
  A nix-build that cannot start counts as a failed build."
  []
  (try
    (let [proc (process {:out :string :err :pipe}
                        "nix-build" "--no-out-link" system-file
                        "-A" "pkgs.cmacs-eca-upstream-guard")
          log  (with-open [r (io/reader (:err proc))]
                 (mapv (fn [line]
                         (binding [*out* *err*] (println line))
                         line)
                       (line-seq r)))]
      {:ok? (zero? (:exit @proc)) :log log})
    (catch java.io.IOException e
      {:ok? false :log [(str "cannot run nix-build: " (ex-message e))]})))

(defn missing-names
  "Names the guard reported MISSING, as {:name :kind}, deduplicated (nix
  repeats the failing log tail in its error summary)."
  [log]
  (->> log
       (keep #(re-find #"(\S+)\s+(fn|var|prop@\S+)\s+MISSING" %))
       (map (fn [[_ name kind]] {:name name :kind kind}))
       distinct))

(defn edit-distance
  "Levenshtein distance between strings `a` and `b`."
  [^String a ^String b]
  (peek
   (reduce (fn [prev ca]
             (reduce (fn [row j]
                       (conj row (min (inc (peek row))
                                      (inc (nth prev (inc j)))
                                      (+ (nth prev j)
                                         (if (= ca (.charAt b j)) 0 1)))))
                     [(inc (first prev))]
                     (range (count b))))
           (vec (range (inc (count b))))
           a)))

(defn source-names
  "Every eca-prefixed token in the client's .el files: symbols and
  property names, plus any that appear only in comments or docstrings."
  [store-path]
  (->> (fs/glob store-path "**.el")
       (mapcat #(re-seq #"(?<![\w-])eca[\w-]*\w" (slurp (str %))))
       set))

(defn rename-hints
  "Up to three [distance name] pairs from `names` closest to `missing`,
  nearest first. A rename usually changes a few characters; the cutoff
  scales with the name's length so short names do not match noise."
  [names missing]
  (let [limit (max 2 (quot (count missing) 5))]
    (->> names
         (remove #{missing})
         (filter #(<= (abs (- (count %) (count missing))) limit))
         (map (fn [n] [(edit-distance missing n) n]))
         (filter (fn [[d]] (<= d limit)))
         sort
         (take 3))))

(defn guard-failure
  "Classify a failed guard build from its log: {:cause :missing :names},
  {:cause :load :detail} when the guard could not load the eca package,
  or {:cause :other}."
  [log]
  (let [names (missing-names log)
        load  (some #(re-find #"cannot load eca package: .*" %) log)]
    (cond (seq names) {:cause :missing :names names}
          load        {:cause :load :detail load}
          :else       {:cause :other})))

(defn report-guard-failure [{:keys [cause names detail]} store-path]
  (case cause
    :missing
    (let [source (source-names store-path)]
      (println "guard: the new eca-emacs lacks names the adapter wraps:")
      (doseq [{:keys [name kind]} names
              :let [hints (rename-hints source name)]]
        (println (format "  %-44s %s" name kind))
        (println
         (if (seq hints)
           (str "    maybe renamed to: "
                (str/join ", " (for [[d n] hints]
                                 (format "%s (%d edit%s)"
                                         n d (if (= 1 d) "" "s")))))
           "    no similar name in the new source"))))
    :load
    (println (str "guard: the new eca-emacs does not load (a file or"
                  " feature may be renamed):\n  " detail))
    :other
    (println "guard: the build failed before the guard could judge the"
             "pin; see the nix log above.")))

(defn check-client!
  "Build the guard against the new client pin. On failure report, restore
  the old pin, and exit 1. A shutdown hook also restores the old pin if
  the run is interrupted mid-build."
  [{:keys [old-block store-path]}]
  (let [settled? (atom false) ; pin passed, or already restored
        restore! (fn []
                   (when-not @settled? (restore-client-block! old-block)))]
    (.addShutdownHook (Runtime/getRuntime) (Thread. ^Runnable restore!))
    (println "guard: building cmacs-eca-upstream-guard against the new pin")
    (let [{:keys [ok? log]} (build-guard)]
      (if ok?
        (do (reset! settled? true)
            (println "guard: pass"))
        (let [failure (guard-failure log)]
          (report-guard-failure failure store-path)
          (restore!)
          (reset! settled? true)
          (println (str "restored the old client pin in " overlay-file
                        "; server pin left unchanged."))
          (println
           (if (= :other (:cause failure))
             "fix the build error above, then rerun."
             (str "fix emacs-conf/config/services/eca/upstream.el"
                  " (and tools/eca-upstream-guard.el), then rerun.")))
          (System/exit 1))))))

;;; --- server (eca) ----------------------------------------------------------

(defn server-latest-tag
  "The tag eca-emacs itself would treat as latest: releases[0] from the full
  list (prereleases included), not the /releases/latest endpoint."
  []
  (-> (gh-get (format "https://api.github.com/repos/%s/releases?per_page=1"
                      server-repo))
      first :tag_name))

(def server-pin-re #"(defvar ck/eca-server-version \")[^\"]+(\")")

(defn update-server! [tag]
  (let [version (or tag (server-latest-tag))
        _       (println (format "server: eca %s" version))
        old     (slurp eca-el-file)
        n       (count (re-seq server-pin-re old))]
    (when (not= 1 n)
      (println (format "error: expected 1 ck/eca-server-version in %s, found %d"
                       eca-el-file n))
      (System/exit 1))
    (let [new (str/replace old server-pin-re (str "$1" version "$2"))]
      (if (= old new)
        (println "  server already up to date")
        (do (spit eca-el-file new)
            (println (format "  -> %s\n     ck/eca-server-version %s"
                             eca-el-file version)))))))

;;; --- cli -------------------------------------------------------------------

(defn parse-args [args]
  (loop [a args, out {}]
    (if-let [[flag v & rest] (seq a)]
      (case flag
        "--client" (recur rest (assoc out :client v))
        "--server" (recur rest (assoc out :server v))
        (do (println (format "unknown arg: %s" flag)) (System/exit 2)))
      out)))

(defn -main [& args]
  (assert-system-uses-repo!)
  (let [{:keys [client server]} (parse-args args)
        client-update (update-client! client)]
    ;; Check the client before touching the server, so a failing client
    ;; leaves both pins where they were.
    (when (:changed? client-update)
      (check-client! client-update))
    (update-server! server)
    (println "done. rebuild emacs + refresh loadpath for the client;"
             "eca re-downloads the server on next start.")))

(apply -main *command-line-args*)

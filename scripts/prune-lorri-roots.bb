#!/usr/bin/env bb
;; Prune lorri's GC roots down to the active shell per nix file.
;;
;; lorri keys its roots by nix file: ~/.cache/lorri/gc_roots/<dir>/gc_root/
;; holds
;;
;;   - `nix_file`: a link to the project's shell.nix or flake.nix;
;;   - `shell_gc_root`: a link to the bash export of the environment that
;;     `lorri direnv` loads. For flake roots it is a text file: it names
;;     store paths in its text, but Nix records no references for it, so
;;     it keeps nothing else alive. Older shell.nix roots link to a
;;     `lorri-keep-env-hack-*` directory instead; that directory is the
;;     root itself, and no shell links sit next to it;
;;   - one `<hash>-<name>-env` link per shell lorri ever built (flake
;;     roots). These are what keep each shell's closure in the store, and
;;     lorri never removes old ones.
;;
;; Each link is registered as an indirect root: /nix/var/nix/gcroots/auto
;; holds a link to it. Deleting the link here unroots its shell, and the
;; next garbage collection drops the dangling auto entry with it.
;;
;; nh clean leaves all of these alone: nh 4.4 ages out only `result*` links
;; in gcroots/auto and roots under `.direnv/` or `direnv/layouts/`
;; (crates/nh-clean/src/clean.rs, `gcroot_matches_filter`). This script:
;;
;;   1. runs `lorri gc rm`, which drops every root directory whose nix file
;;      is gone (a project that moved from shell.nix to flake.nix);
;;   2. in each remaining directory, removes every shell link except the
;;      active one: the shell whose store path the `shell_gc_root` export
;;      names. A directory where no shell link matches is skipped with a
;;      warning, so an unexpected layout removes nothing.
;;
;; It only removes links; the store paths they held go at the next garbage
;; collection (the nh-clean timer). The lorri-prune user service in
;; nix-conf/modules/dev.nix runs it daily.
;;
;; Usage:
;;   scripts/prune-lorri-roots.bb         # prune roots
;;   scripts/prune-lorri-roots.bb --dry   # only show what would go

(require '[babashka.fs :as fs]
         '[babashka.process :refer [shell]]
         '[cheshire.core :as json]
         '[clojure.string :as str]
         '[taoensso.timbre :as log])

(log/merge-config!
 {:output-fn (fn [{:keys [level msg_]}]
               (str (name level) ": " (force msg_)))})

;;; --- lorri roots -------------------------------------------------------

(defn lorri-roots
  "lorri's root directories as maps of `:gc-dir`, the `:nix-file` it
  builds from, and `:alive?`, whether that file still exists."
  []
  (->> (shell {:out :string} "lorri" "gc" "--json" "info")
       :out
       (#(json/parse-string % true))
       (mapv (fn [{:keys [gc_dir nix_file alive]}]
               {:gc-dir   gc_dir
                :nix-file nix_file
                :alive?   alive}))))

(defn- -store-target
  "The store path `path` links to, or nil when it is not a store link."
  [path]
  (when (fs/sym-link? path)
    (let [target (str (fs/read-link path))]
      (when (str/starts-with? target "/nix/store/")
        target))))

(defn- -export-text
  "The bash export `shell_gc_root` links to, or nil. Flake roots link to
  the export file itself; older shell.nix roots link to a
  `lorri-keep-env-hack-*` directory that holds it as `bash-export`."
  [shell-gc-root]
  (let [file (if (fs/directory? shell-gc-root)
               (fs/path shell-gc-root "bash-export")
               shell-gc-root)]
    (when (fs/regular-file? file)
      (slurp (str file)))))

(def ^:private lorri-links
  "The gc_root entries lorri keeps for itself; never shell links, even if
  one resolves into the store (a project file managed by home-manager)."
  #{"nix_file" "shell_gc_root"})

(defn gc-root-contents
  "What `gc-dir`'s gc_root directory holds: `:export`, a delay of the text
  of the environment `shell_gc_root` links to (nil when absent), and
  `:shells`, one `{:path ... :target ...}` per shell root link."
  [gc-dir]
  (let [dir (fs/path gc-dir "gc_root")]
    (when (fs/directory? dir)
      {:export (delay (-export-text (fs/path dir "shell_gc_root")))
       :shells (keep (fn [path]
                       (when-not (lorri-links (str (fs/file-name path)))
                         (when-let [target (-store-target path)]
                           {:path   path
                            :target target})))
                     (fs/list-dir dir))})))

(defn- -dir-plan
  "The prune step for one live root: nil when it holds at most one shell,
  `{:nix-file ... :unresolved? true}` when no shell matches the export, or
  `{:nix-file ... :links [...] :kept n}`, where `:links` are the shell
  links the export does not name and `:kept` counts those it does."
  [{:keys [gc-dir nix-file]}]
  (let [{:keys [export shells]} (gc-root-contents gc-dir)
        active?                 (fn [{:keys [target]}]
                                  (some-> @export
                                          (str/includes? target)))
        kept                    (count (filter active? shells))]
    (cond
      (<= (count shells) 1) nil
      (zero? kept)          {:nix-file    nix-file
                             :unresolved? true}
      :else                 {:nix-file nix-file
                             :links    (mapv :path (remove active? shells))
                             :kept     kept})))

(defn prune-plan
  "What to remove, from lorri's `roots`:

  - `:dead`: roots lorri reports as dead (nix file gone), for the log;
    `lorri gc rm` decides what it removes.
  - `:stale`: `{:nix-file ... :links [...]}` per live root, where `:links`
    are its inactive shell links.
  - `:unresolved`: live roots with several shells but none named by the
    export; they are left alone."
  [roots]
  (let [steps (keep -dir-plan (filter :alive? roots))]
    {:dead       (remove :alive? roots)
     :stale      (remove :unresolved? steps)
     :unresolved (filter :unresolved? steps)}))

(defn apply-plan!
  "Removes what `plan` names, or with `dry?` only logs it."
  [{:keys [dead stale unresolved]} dry?]
  (let [verb (if dry? "would remove" "removing")]
    (doseq [{:keys [nix-file]} dead]
      (log/info (format "%s all roots of %s (file gone)" verb nix-file)))
    ;; Always run it: lorri owns the dead check, and it is a no-op when
    ;; nothing is dead. A failure here must not skip the prune below.
    (when-not dry?
      (let [{:keys [exit]} (shell {:continue true} "lorri" "gc" "rm")]
        (when-not (zero? exit)
          (log/warn (format "lorri gc rm exited %d; pruning anyway"
                            exit)))))
    (doseq [{:keys [nix-file]} unresolved]
      (log/warn (str "skipping " nix-file
                     ": no shell link matches its shell_gc_root export")))
    (doseq [{:keys [nix-file links kept]} stale]
      (when (< 1 kept)
        (log/warn (format "%s: its export names %d shells; keeping all %d"
                          nix-file kept kept)))
      (log/info (format "%s %d old shell(s) of %s"
                        verb (count links) nix-file))
      (when-not dry?
        ;; The lorri daemon may remove a link between listing and here.
        (run! fs/delete-if-exists links)))
    (log/info (format "%s %d old shell(s) in total"
                      verb (reduce + 0 (map (comp count :links) stale))))))

;;; --- cli ---------------------------------------------------------------

(defn parse-args
  "Options from the command line: `--dry` sets `:dry?`; anything else
  throws with `:exit 2`."
  [args]
  (reduce (fn [opts a]
            (if (= a "--dry")
              (assoc opts :dry? true)
              (throw (ex-info (str "unknown arg: " a)
                              {:arg a :exit 2}))))
          {}
          args))

(defn prune!
  "Prunes lorri's roots; with `:dry?`, only shows what would go."
  [{:keys [dry?]}]
  (apply-plan! (prune-plan (lorri-roots)) dry?))

(defn -main [& args]
  (try
    (prune! (parse-args args))
    (catch clojure.lang.ExceptionInfo e
      (log/error (ex-message e))
      (System/exit (:exit (ex-data e) 1)))
    (catch java.io.IOException e
      (log/error (ex-message e))
      (System/exit 1))))

(when (= *file* (System/getProperty "babashka.file"))
  (apply -main *command-line-args*))

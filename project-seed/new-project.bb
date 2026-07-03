#!/usr/bin/env bb
;; Minimal scaffolding engine for a derived featureset. Everything that
;; defines WHAT gets seeded (templates, features, file manifest, examples)
;; lives at $SHAREPATH/project-seed/ and is data; this script only renders
;; that featureset and runs the ready-to-run steps.
;;
;; Usage:
;;   bb new-project.bb <spec.edn | example-name | inline-edn> [--skip-nix]
;;   bb new-project.bb --list
;;
;; See README.md here for engine behavior, and
;; $SHAREPATH/project-seed/README.md for the featureset.

(require '[babashka.fs :as fs]
         '[babashka.process :as p]
         '[clojure.edn :as edn]
         '[clojure.string :as str]
         '[selmer.parser :as selmer]
         '[selmer.util :as selmer-util])

(selmer-util/turn-off-escaping!)

(def script-dir (str (fs/parent (fs/absolutize *file*))))

;; The featureset lives in $SHAREPATH (Dropbox-synced, git-free); this
;; engine stays in the config repo.
(def share-path
  (or (System/getenv "SHAREPATH")
      (str (fs/expand-home "~/Dropbox/lxndr"))))

(def seed-dir      (fs/file share-path "project-seed"))
(def templates-dir (fs/file seed-dir "templates"))
(def examples-dir  (fs/file seed-dir "examples"))

(defn die [& msg]
  (binding [*out* *err*]
    (apply println "error:" msg))
  (System/exit 1))

(defn read-seed-edn
  "Read an EDN file from the seed dir, with a helpful death when absent."
  [filename]
  (let [f (fs/file seed-dir filename)]
    (when-not (fs/exists? f)
      (die (str filename " not found at " f
                " - is Dropbox synced (or SHAREPATH set)?")))
    (try (edn/read-string (slurp f))
         (catch Exception e
           (die (str "unreadable " f ": " (ex-message e)))))))

(defn system-nixpkgs-rev
  "The nixpkgs rev the running system is pinned to, parsed from this config
  repo's nix-conf/system.nix (fetchTarball archive URL). Nil when absent."
  []
  (let [f (fs/file script-dir ".." "nix-conf" "system.nix")]
    (when (fs/exists? f)
      (second (re-find #"nixpkgs/archive/([0-9a-f]+)\.tar\.gz" (slurp f))))))

(defn list-featureset! []
  (let [features (read-seed-edn "features.edn")]
    (println (str "Featureset at " seed-dir "\n"))
    (println "Features:")
    (doseq [[k {:keys [doc options]}] (sort-by key features)]
      (println (str "  " k))
      (println (str "    " doc))
      (doseq [[opt opt-doc] options]
        (println (str "    " opt " - " opt-doc))))
    (println "\nExamples (usable by bare name):")
    (doseq [f (sort-by fs/file-name (fs/list-dir examples-dir "*.edn"))]
      (println (str "  " (fs/file-name f)))
      (print (str/replace (slurp (fs/file f)) #"(?m)^" "    ")))
    (flush)))

(defn spec-source
  "Arg is inline EDN (starts with `{`), a path to an EDN file, or the bare
  name of an example in the seed dir."
  [arg]
  (cond
    (str/starts-with? (str/trim arg) "{") arg
    (fs/exists? arg)                      (slurp arg)
    :else
    (let [example (fs/file examples-dir (str arg ".edn"))]
      (if (fs/exists? example)
        (slurp example)
        (die "no such spec file or example:" arg "- try --list")))))

(defn parse-spec [arg]
  (let [spec (try (edn/read-string (spec-source arg))
                  (catch Exception e
                    (die "unreadable EDN:" (ex-message e))))]
    (when-not (map? spec)
      (die "spec must be an EDN map, got:" (pr-str spec)))
    spec))

(defn ->ctx
  "Validate the spec against the featureset and build the render context:
  feature defaults, then the spec itself, then derived keys, then one true
  flag per selected feature flag (what the templates branch on)."
  [{:keys [name features nixpkgs-rev] :as spec}]
  (when-not (and (string? name) (re-matches #"[a-z][a-z0-9-]*" name))
    (die ":name must be a kebab-case string, got:" (pr-str name)))
  (let [feature-defs (read-seed-edn "features.edn")
        features     (set features)
        unknown      (remove feature-defs features)]
    (when (seq unknown)
      (die "unknown :features" (pr-str (vec unknown))
           "- known:" (pr-str (vec (keys feature-defs))) "(see --list)"))
    (let [selected      (map feature-defs features)
          flags         (into #{} (mapcat :flags) selected)
          defaults      (apply merge {} (map :defaults selected))
          ;; nil rev is fine: templates fall back to the registry ref
          rev           (or nixpkgs-rev (system-nixpkgs-rev))]
      (println (str "  nixpkgs rev: " (or rev "none (registry fallback)")))
      (merge defaults
             spec
             {:description (or (:description spec) "a new Clojure project")
              :ns-name     name
              :ns-path     (str/replace name "-" "_")
              :nixpkgs-rev rev
              :today       (str (java.time.LocalDate/now))}
             (zipmap flags (repeat true))))))

(defn render-files!
  "Render every [template, target-path-template] pair in the manifest; the
  target paths go through selmer with the same context as the contents."
  [dir ctx]
  (doseq [[template rel-path-tmpl] (read-seed-edn "manifest.edn")]
    (let [rel-path (selmer/render rel-path-tmpl ctx)
          source   (fs/file templates-dir template)
          target   (fs/file dir rel-path)]
      (when-not (fs/exists? source)
        (die "manifest names a missing template:" (str source)))
      (let [rendered (-> (slurp source)
                         (selmer/render ctx)
                         ;; collapse blank-line runs left by removed blocks
                         (str/replace #"\n{3,}" "\n\n"))]
        (fs/create-dirs (fs/parent target))
        (spit target rendered)
        (println "  wrote" rel-path)))))

(defn create-dirs!
  "Create every directory named in dirs.edn (selmer-rendered relative
  paths). Plain empty dirs; git won't track them, which is fine - they
  exist so classpath roots (resources) and scratch/data dirs (data) are
  present from the moment the project is seeded."
  [dir ctx]
  (doseq [rel-tmpl (read-seed-edn "dirs.edn")]
    (let [rel (selmer/render rel-tmpl ctx)]
      (fs/create-dirs (fs/file dir rel))
      (println "  mkdir" rel))))

(defn sh!
  "Run cmd in dir, streaming output; dies on non-zero exit."
  [dir & cmd]
  (println (str "\n$ " (str/join " " cmd)))
  (apply p/shell {:dir (str dir)} cmd))

(defn sh?!
  "Like sh! but tolerated: warns and continues on non-zero exit."
  [dir & cmd]
  (println (str "\n$ " (str/join " " cmd) "  (best-effort)"))
  (let [res (apply p/shell {:dir (str dir) :continue true} cmd)]
    (when-not (zero? (:exit res))
      (println (str "warning: `" (str/join " " cmd)
                    "` exited " (:exit res) "; continuing")))))

(defn -main [& args]
  (let [{flags true, positional false} (group-by #(str/starts-with? % "--") args)
        skip-nix? (boolean (some #{"--skip-nix"} flags))]
    (when-let [bad (seq (remove #{"--skip-nix" "--list"} flags))]
      (die "unknown flags:" (pr-str (vec bad))))
    (when (some #{"--list"} flags)
      (list-featureset!)
      (System/exit 0))
    (when-not (= 1 (count positional))
      (die "usage: bb new-project.bb"
           "<spec.edn | example-name | inline-edn> [--skip-nix] | --list"))
    (let [spec  (parse-spec (first positional))
          owner (or (:owner spec) "Camsbury")
          _     (when-not (and (string? owner)
                               (re-matches #"[A-Za-z][A-Za-z0-9-]*" owner))
                  (die ":owner must be a plain directory name, got:"
                       (pr-str owner)))
          ctx   (->ctx spec)
          ;; owner pins the depth to ~/projects/<owner>/<name>, which the
          ;; ../../dynamic-alpha local-root deps rely on
          dir   (fs/file (str (fs/expand-home "~/projects")) owner (:name ctx))]
      (when-not (fs/exists? templates-dir)
        (die "templates not found at" (str templates-dir)
             "- is Dropbox synced (or SHAREPATH set)?"))
      (when (fs/exists? dir)
        (die "target already exists:" (str dir)))
      (println "Seeding" (str dir))
      (fs/create-dirs dir)
      (render-files! dir ctx)
      (create-dirs! dir ctx)

      ;; Flakes only see git-tracked files, so init + add before any nix step.
      (sh! dir "git" "init")
      (sh! dir "git" "add" "-A")
      (sh! dir "direnv" "allow" ".")

      (if skip-nix?
        (println "\nSkipping nix steps (--skip-nix).")
        (do
          ;; one-shot build so `lorri direnv` (via .envrc) is instant later
          (sh! dir "lorri" "watch" "--flake" "." "--once")
          ;; bump the seeded dep versions to latest
          (sh?! dir "nix" "develop" "--command"
                "clojure" "-M:outdated" "--upgrade" "--force")))

      (println (str "\nDone. Next steps:\n"
                    "  1. cd " dir "  (direnv loads the flake env)\n"
                    "  2. review + commit the initial scaffold\n"
                    "  3. open an ECA client there and orient")))))

(apply -main *command-line-args*)

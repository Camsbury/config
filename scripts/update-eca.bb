#!/usr/bin/env bb
;; Update both eca "recipes" together:
;;
;;   1. the eca-emacs CLIENT pin in nix-conf/overlays/emacs.nix
;;      (version + rev + hash), and
;;   2. the eca SERVER version pin `ck/eca-server-version' in
;;      emacs-conf/config/services/eca.el.
;;
;; Client and server are separate repos with independent version numbers;
;; this keeps the pair we run moving together instead of drifting. It only
;; rewrites the two recipe files: no nix build, no reload (do those yourself,
;; e.g. rebuild emacs + M-x latest-loadpath for the client, and let eca
;; re-download the server on next start).
;;
;; Usage:
;;   scripts/update-eca.bb                     # both to latest
;;   scripts/update-eca.bb --client <rev>      # pin client to a commit
;;   scripts/update-eca.bb --server <tag>      # pin server to a release tag
;;   (flags combine; omit either to take that side's latest)

(require '[babashka.fs :as fs]
         '[babashka.http-client :as http]
         '[babashka.process :refer [shell]]
         '[cheshire.core :as json]
         '[clojure.string :as str])

(def client-repo "editor-code-assistant/eca-emacs")
(def server-repo "editor-code-assistant/eca")

(def repo-root (-> *file* fs/canonicalize fs/parent fs/parent))
(def overlay-file (str (fs/path repo-root "nix-conf/overlays/emacs.nix")))
(def eca-el-file  (str (fs/path repo-root "emacs-conf/config/services/eca.el")))

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

(defn prefetch-hash
  "SRI hash for fetchFromGitHub at `sha` (same NAR hash as a github: input)."
  [sha]
  (-> (shell {:out :string} "nix" "flake" "prefetch" "--json"
             (format "github:%s/%s" client-repo sha))
      :out (json/parse-string true) :hash))

(def client-block-re
  ;; Anchored on `eca =` so the other packages' bindings are never touched.
  #"(?s)(eca =\s+let\s+version = \")[^\"]+(\";\s+rev = \")[^\"]+(\";\s+hash = \")[^\"]+(\";)")

(defn update-client! [ref]
  (let [{:keys [sha date]} (client-commit (or ref "HEAD"))
        version (melpa-version date)
        _       (println (format "client: eca-emacs %s (%s, %s)"
                                 version (subs sha 0 12) date))
        hash    (prefetch-hash sha)
        old     (slurp overlay-file)
        n       (count (re-seq client-block-re old))]
    (when (not= 1 n)
      (println (format "error: expected 1 eca block in %s, found %d"
                       overlay-file n))
      (System/exit 1))
    (let [new (str/replace old client-block-re
                           (str "$1" version "$2" sha "$3" hash "$4"))]
      (if (= old new)
        (println "  client already up to date")
        (do (spit overlay-file new)
            (println (format "  -> %s\n     version %s\n     rev     %s\n     hash    %s"
                             overlay-file version sha hash)))))))

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
  (let [{:keys [client server]} (parse-args args)]
    (update-client! client)
    (update-server! server)
    (println "done. rebuild emacs + refresh loadpath for the client;"
             "eca re-downloads the server on next start.")))

(apply -main *command-line-args*)

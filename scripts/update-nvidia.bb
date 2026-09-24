#!/usr/bin/env bb
;; Bump the pinned NVIDIA driver in
;; $DEV_HOME/Camsbury/config/nix-conf/modules/rtx-5070-ti.nix.
;;
;; Finds the newest Linux x64 driver on NVIDIA's download page for the card,
;; prefetches every source that nixpkgs' `nvidiaPackages.mkDriver` fetches
;; for that version, and rewrites `version` plus each hash attr in place.
;; It only rewrites the module: no nixos-rebuild.
;;
;; "Newest" is the numeric maximum of every listed version, across release
;; branches (the page lists both 580.x and 595.x). Pass a version to pin a
;; specific branch.
;;
;; The fetch URLs and hash kinds mirror nixpkgs'
;; pkgs/os-specific/linux/nvidia-x11 (generic.nix, kernel-modules.nix,
;; settings.nix, persistenced.nix). If nixpkgs changes a fetcher there, the
;; hash this script computes stops matching and the rebuild will say so.
;; nvidia-settings and nvidia-persistenced are assumed to be tagged with the
;; driver version; if NVIDIA ever skips a tag, mkDriver needs
;; `settingsVersion` / `persistencedVersion`, which this script does not set.
;;
;; A hash is re-fetched only when the version changes, when it is currently
;; a lib.fake* placeholder, or with --force. GitHub tarballs go first so a
;; missing tag fails before the multi-hundred-MB .run download. Nix shows
;; download progress on stderr.
;;
;; Usage:
;;   scripts/update-nvidia.bb              # newest listed version
;;   scripts/update-nvidia.bb 595.104.02   # a specific version
;;   scripts/update-nvidia.bb --force      # re-hash everything

(require '[babashka.fs :as fs]
         '[babashka.http-client :as http]
         '[babashka.process :refer [shell]]
         '[cheshire.core :as json]
         '[clojure.string :as str]
         '[taoensso.timbre :as log])

(log/merge-config!
 {:output-fn (fn [{:keys [level msg_]}]
               (str (name level) ": " (force msg_)))})

(defn module-file []
  (let [dev-home (System/getenv "DEV_HOME")]
    (when (str/blank? dev-home)
      (throw (ex-info "DEV_HOME is not set" {})))
    (str (fs/path dev-home
                  "Camsbury/config/nix-conf/modules/rtx-5070-ti.nix"))))

(def driver-list-url
  ;; psid/pfid select the RTX 50 series / RTX 5070 Ti; osid 12 is Linux x64.
  (str "https://www.nvidia.com/Download/processFind.aspx"
       "?psid=131&pfid=1068&osid=12&lid=1&whql=1&lang=en-us&ctk=0"))

;;; --- version -----------------------------------------------------------

(defn version-key
  "Numeric sort key for a dotted version, padded so that `595.80` sorts as
  595.80.0 rather than by vector length."
  [v]
  (let [parts (mapv parse-long (str/split v #"\."))]
    (into parts (repeat (- 3 (count parts)) 0))))

(defn listed-versions
  "Versions from the Version column of NVIDIA's driver list page."
  [html]
  (->> (re-seq #"class=\"gridItem\">(\d+\.\d+(?:\.\d+)?)</td>" html)
       (map second)
       distinct))

(defn latest-version []
  (let [versions (listed-versions (:body (http/get driver-list-url)))]
    (when (empty? versions)
      (throw (ex-info "no driver versions found on NVIDIA's page"
                      {:url driver-list-url})))
    (last (sort-by version-key versions))))

;;; --- sources -----------------------------------------------------------

(defn github-archive [repo v]
  (format "https://github.com/NVIDIA/%s/archive/%s.tar.gz" repo v))

(defn nvidia-archive [repo v]
  (format "https://download.nvidia.com/XFree86/%s/%s-%s.tar.bz2" repo repo v))

(defn run-file [host v]
  (format "https://%s/XFree86/Linux-x86_64/%s/NVIDIA-Linux-x86_64-%s.run"
          host v v))

(defn sources
  "What mkDriver fetches for version `v`, in fetch order. `:unpack?` marks a
  fetchzip-style NAR hash of the unpacked tree; otherwise the hash is of the
  file itself. `:urls` are in nixpkgs' mirror order."
  [v]
  [{:attr "openSha256" :unpack? true
    :urls [(github-archive "open-gpu-kernel-modules" v)]}
   {:attr "settingsSha256" :unpack? true
    :urls [(github-archive "nvidia-settings" v)
           (nvidia-archive "nvidia-settings" v)]}
   {:attr "persistencedSha256" :unpack? true
    :urls [(github-archive "nvidia-persistenced" v)
           (nvidia-archive "nvidia-persistenced" v)]}
   {:attr "sha256_64bit" :unpack? false
    :urls [(run-file "us.download.nvidia.com" v)
           (run-file "download.nvidia.com" v)]}])

(defn first-published
  "The first of `urls` that exists. Moves to the next URL only on a 404, as
  nixpkgs would: any other failure throws, so a GitHub outage never pins
  the mirror's hash in place of GitHub's."
  [attr urls]
  (or (some (fn [url]
              (let [{:keys [status]} (http/head url {:throw false})]
                (case (long status)
                  200 url
                  404 nil
                  (throw (ex-info (format "HTTP %d for %s" status url)
                                  {:attr attr :url url})))))
            urls)
      (throw (ex-info (str "no published source for " attr)
                      {:attr attr :urls urls}))))

(defn prefetch
  "SRI hash of `url` as nix computes it for the fixed-output fetch."
  [url unpack?]
  (-> (apply shell {:out :string}
             (concat ["nix" "--extra-experimental-features" "nix-command"
                      "store" "prefetch-file" "--json"]
                     (when unpack? ["--unpack"])
                     [url]))
      :out
      (json/parse-string true)
      :hash))

(defn source-hash [{:keys [attr unpack? urls]}]
  (let [url (first-published attr urls)]
    (log/info (format "%s <- %s" attr url))
    (prefetch url unpack?)))

;;; --- module rewrite ----------------------------------------------------

(defn attr-re
  "Matches `name = \"...\";` or `name = lib.fakeSha256;` (or lib.fakeHash)."
  [attr]
  (re-pattern
   (str "(\\b" attr "\\s*=\\s*)"
        "(?:\"([^\"]*)\"|lib\\.fake(?:Sha256|Hash))"
        "(\\s*;)")))

(defn current-value
  "The quoted value of `attr` in `text`, nil when it is a lib.fake* hash.
  Throws unless the attr appears exactly once, which is what makes the
  regex rewrite safe."
  [text attr]
  (let [ms (re-seq (attr-re attr) text)]
    (when (not= 1 (count ms))
      (throw (ex-info (format "expected exactly one `%s`, found %d"
                              attr (count ms))
                      {:attr attr :matches (count ms)})))
    (nth (first ms) 2)))

(defn rewrite
  "`text` with each attr in `values` (attr -> string) set to that string.
  Callers read every attr with `current-value` first, so each regex here
  matches exactly once."
  [text values]
  (reduce-kv (fn [t attr v]
               (str/replace t (attr-re attr)
                            (str "$1\"" (str/re-quote-replacement v) "\"$3")))
             text
             values))

(def pinned-attrs
  ["version" "sha256_64bit" "openSha256" "settingsSha256"
   "persistencedSha256"])

;;; --- cli ---------------------------------------------------------------

(defn parse-args [args]
  (reduce (fn [opts a]
            (cond
              (= a "--force") (assoc opts :force? true)
              (re-matches #"\d+\.\d+(?:\.\d+)?" a) (assoc opts :version a)
              :else (throw (ex-info (str "unknown arg: " a)
                                    {:arg a :exit 2}))))
          {}
          args))

(defn update-module! [{:keys [version force?]}]
  (let [file    (module-file)
        _       (log/info (str "module " file))
        text    (slurp file)
        current (zipmap pinned-attrs
                        (map #(current-value text %) pinned-attrs))
        target  (or version (latest-version))
        bump?   (not= target (get current "version"))
        stale   (filter #(or force? bump? (nil? (get current (:attr %))))
                        (sources target))]
    (log/info (format "current %s, target %s"
                      (get current "version") target))
    (if (empty? stale)
      (log/info "already pinned with real hashes; --force to re-hash")
      (let [values (-> (into {} (map (juxt :attr source-hash)) stale)
                       (assoc "version" target))]
        (spit file (rewrite text values))
        (log/info
         (str/join "\n  " (cons (str "updated " file)
                                (for [a pinned-attrs
                                      :when (contains? values a)]
                                  (str a " = " (get values a))))))))))

(defn -main [& args]
  (try
    (update-module! (parse-args args))
    (catch clojure.lang.ExceptionInfo e
      (log/error (ex-message e) (dissoc (ex-data e) :exit))
      (System/exit (:exit (ex-data e) 1)))
    (catch java.io.IOException e
      (log/error (ex-message e))
      (System/exit 1))))

(when (= *file* (System/getProperty "babashka.file"))
  (apply -main *command-line-args*))

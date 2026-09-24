#!/run/current-system/sw/bin/bb
;; Sort synced mail into folders by the rules in mail-rules.edn.
;;
;; mbsync.service (nix-conf/modules/email.nix) runs this after
;; `mbsync -a`. The mu database has one writer at a time: while mu4e
;; is open, its `mu server` holds the write lock, and `mu index`,
;; `mu add`, `mu remove` and `mu move` fail. So this script moves
;; message files itself, which needs no lock, and uses mu only to
;; find messages and to record changes:
;;
;; 1. Index, so the rules see the mail from this sync.
;; 2. Move each matching message file into its sink folder.
;; 3. Record the moves in mu: add the new paths, remove the old ones.
;;
;; While mu4e holds the lock, steps 1 and 3 are skipped. mu4e then
;; picks up the moves on its own periodic index
;; (mu4e-update-interval in emacs-conf/config/services/email.el), and
;; mail that arrived since mu4e's last index is sorted on a later run.
;;
;; No step uses `mu index --lazy-check`, here or in mu4e. A lazy index
;; skips a folder whose timestamp is in the same second as its last
;; scan, while its cleanup still drops paths that no longer exist. A
;; message moved in that second then vanishes from mu.

(require '[babashka.fs :as fs]
         '[babashka.process :as p]
         '[cheshire.core :as json]
         '[clojure.edn :as edn]
         '[clojure.string :as str]
         '[taoensso.timbre :as log])

(def maildir-root
  (str (fs/home) "/Maildir"))

(def rules-file
  (str (fs/home) "/Dropbox/lxndr/mail-rules.edn"))

;; `mu find` exits with this code when nothing matches.
(def no-matches-exit 2)

;; mu exits with this code when another mu process (mu4e's server)
;; holds the database write lock.
(def db-locked-exit 19)

;; Messages in folders with these names (any case, at any depth) are
;; never moved, even when a rule's query (with --include-related)
;; returns them. Keep in step with the mu4e sent, drafts and trash
;; folders in emacs-conf/config/services/email.el.
(def fixed-folders #{"sent" "drafts" "trash"})

;; Paths per `mu add` / `mu remove` call, to stay far below the
;; argument-length limit.
(def mu-batch-size 200)

(defn run
  [& args]
  (apply p/shell {:continue true :out :string :err :string} args))

(defn mu-write!
  "Run a mu command that writes the database. Returns :done, or
  :locked when mu4e holds the lock; throws on any other failure."
  [& args]
  (let [{:keys [exit err]} (apply run "mu" args)]
    (cond
      (zero? exit)            :done
      (= db-locked-exit exit) :locked
      :else (throw (ex-info (str "mu " (first args) " failed")
                            {:args args :exit exit
                             :err  (str/trim err)})))))

(defn folder
  "Folder name `s` in mu's form, with one leading slash."
  [s]
  (str "/" (str/replace s #"^/+" "")))

(defn folder-dir
  "The directory of mu folder `f` (like \"/personal/Inbox\")."
  [f]
  (str (fs/path maildir-root (subs (folder f) 1))))

(defn parse-query-key
  [[k v]]
  (case k
    :from
    (if (string? v)
      (str "from:" v)
      (str "("
           (->> v
                (map #(str "from:" %))
                (str/join " OR "))
           ")"))
    (str (name k) ":" v)))

(defn parse-query
  [query]
  (->> query
       (map parse-query-key)
       (str/join " AND ")))

(defn find-messages
  "Messages matching `query` plus the rest of their threads, as maps
  with `:path` and `:maildir` (a folder like \"/personal/Inbox\").
  Reading works while mu4e holds the lock."
  [query]
  (let [{:keys [exit out err]}
        (run "mu" "find" (parse-query query)
             "--include-related" "--format=json")]
    (cond
      (zero? exit)
      (for [m (json/parse-string out)]
        {:path (get m ":path") :maildir (get m ":maildir")})

      (= no-matches-exit exit)
      []

      :else
      (throw (ex-info "mu find failed"
                      {:query query :exit exit :err (str/trim err)})))))

(defn in-folder?
  "True when `maildir` is folder `f` or a folder below it."
  [f maildir]
  (or (= maildir f)
      (str/starts-with? maildir (str f "/"))))

(defn fixed-folder?
  [maildir]
  (some fixed-folders (str/split (str/lower-case maildir) #"/")))

(defn rule-paths
  "Paths of the messages `rule` moves: those in its source folder (or
  anywhere, without a source) that are not already in its sink."
  [{:keys [query source sink]}]
  (->> (find-messages query)
       (remove (comp fixed-folder? :maildir))
       (filter #(or (nil? source) (in-folder? source (:maildir %))))
       (remove #(in-folder? sink (:maildir %)))
       (map :path)
       distinct))

(def maildir-host
  "This host's name in the form maildir file names use: `/` and `:`
  escaped as octal, as the maildir spec asks. Read from the kernel,
  like gethostname(2), so it needs no name resolution."
  (-> (try (str/trim (slurp "/proc/sys/kernel/hostname"))
           (catch Exception _ "localhost"))
      (str/replace "/" "\\057")
      (str/replace ":" "\\072")))

(defn fresh-file-name
  "A new unique maildir file name that keeps the flags suffix
  (`:2,FS`) of `file-name`, so no flags are lost. It drops mbsync's
  `,U=<uid>`, so the next sync uploads the message into its new
  folder, and it cannot collide with a file already there. This is
  what `mu move --change-name` does."
  [file-name]
  (let [[_ info] (re-find #"(:2,[^:]*)$" file-name)
        unique   (str/replace (str (random-uuid)) "-" "")]
    (str (quot (System/currentTimeMillis) 1000) "." unique "."
         maildir-host info)))

(defn target-path
  "Where the message file at `path` goes in folder `f`: the same new/
  or cur/ subdirectory, under a fresh file name."
  [path f]
  (let [subdir (str (fs/file-name (fs/parent path)))]
    (when (#{"new" "cur"} subdir)
      (str (fs/path (folder-dir f) subdir
                    (fresh-file-name (str (fs/file-name path))))))))

(defn move!
  "Move the message file at `path` into folder `f`. Returns a map
  whose :status is :moved (with :to), :gone when the file no longer
  exists (an earlier rule moved it, or the database is behind), or
  :failed (with :error). A file already at the target is never
  replaced."
  [path f]
  (let [target (target-path path f)
        result {:from path :folder f}]
    (cond
      (not (fs/regular-file? path))
      (assoc result :status :gone)

      (nil? target)
      (assoc result :status :failed :error "not in a new/ or cur/ dir")

      :else
      (try
        (fs/move path target)
        (assoc result :status :moved :to target)
        (catch Exception e
          (assoc result
                 :status :failed
                 :error (str (.getSimpleName (class e)) ": "
                             (ex-message e))))))))

(defn ensure-maildir!
  "Create folder `f` as a maildir (cur/, new/, tmp/) if it is
  missing. Works while mu4e holds the lock. Returns nil, or a failure
  map."
  [f]
  (let [{:keys [exit err]} (run "mu" "mkdir" (folder-dir f))]
    (when-not (zero? exit)
      {:folder f :status :failed :error (str/trim err)})))

(defn apply-rule!
  "Move every message `rule` selects into its sink. Returns the move
  results."
  [{:keys [sink] :as rule}]
  (let [paths (rule-paths rule)]
    (if-let [failure (and (seq paths) (ensure-maildir! sink))]
      [failure]
      (mapv #(move! % sink) paths))))

(defn record-moves!
  "Tell mu about `moves`: add the new paths, then remove the old ones.
  This updates only the moved messages, without a second index pass.
  Returns :done, or :locked when mu4e holds the lock."
  [moves]
  (let [batches (fn [paths] (partition-all mu-batch-size paths))
        run-all (fn [cmd paths]
                  (reduce (fn [_ batch]
                            (let [r (apply mu-write! cmd batch)]
                              (if (= :locked r) (reduced r) r)))
                          :done
                          (batches paths)))]
    (if (= :locked (run-all "add" (map :to moves)))
      :locked
      ;; `mu remove` also deletes the file when it exists; the old
      ;; paths are gone after the move, but never pass one that is
      ;; not.
      (run-all "remove" (remove fs/exists? (map :from moves))))))

(defn -main []
  (let [rules    (for [rule (edn/read-string (slurp rules-file))]
                   (cond-> (update rule :sink folder)
                     (:source rule) (update :source folder)))
        index    (mu-write! "index" "--quiet")
        results  (into [] (mapcat apply-rule!) rules)
        moves    (filter #(= :moved (:status %)) results)
        failures (filterv #(= :failed (:status %)) results)
        record   (if (seq moves) (record-moves! moves) :nothing-moved)]
    (log/info "mail sorted"
              {:index    index
               :record   record
               :moved    (count moves)
               :gone     (count (filter #(= :gone (:status %)) results))
               :failed   (count failures)})
    (when (seq failures)
      (throw (ex-info "some mail moves failed" {:failures failures})))))

;; Log any failure through the same logger as the summary, then exit
;; non-zero so the unit shows as failed.
(try
  (-main)
  (catch Exception e
    (log/error e "mail sort failed" (ex-data e))
    (System/exit 1)))

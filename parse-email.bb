(require '[babashka.process :refer [process]])
(require '[clojure.string :as str])
(require '[clojure.pprint :refer [pprint]])
(require '[babashka.fs :as fs])

(def maildir
  (str (System/getenv "HOME") "/Maildir"))

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

(defn query->cmd
  [query]
  ["mu" "find"
   (parse-query query)
   "--include-related"
   "--fields" "l"])

(defn rule->files
  [{:keys [query source sink]}]
  (let [cmd  (query->cmd query)
        proc (process cmd {:out :string})
        source-filter
        (if source
          #(str/starts-with? % source)
          #(not (str/starts-with? % sink)))
        ]
    (->> @proc
         :out
         str/split-lines
         (map #(clojure.string/replace % #"^.*?/Maildir" ""))
         (remove #(str/includes? % "/sent/"))
         (filter source-filter))))

(defn remove-uid
  [filename]
  (str/replace filename #",U=.*?(?=,|$)" ""))

(defn move-file
  [source sink]
  (let [sink (fs/path sink (remove-uid (fs/file-name source)))]
    (fs/create-dirs (fs/parent sink))
    (when (fs/regular-file? source)
      (fs/move source sink {:replace-existing true}))))

(defn -main []
  (let [rules
        (edn/read-string
          (slurp (str (System/getenv "HOME") "/Dropbox/lxndr/mail-rules.edn")))]
    #_
    (let [{:keys [query]} (first rules)]
      (pprint (parse-query query)))
    (doseq [{:keys [sink] :as rule} rules]
      (doseq [file (rule->files rule)]
        (cond
          (str/includes? file "new")
          (move-file (str maildir file) (str maildir sink "/new"))
          (str/includes? file "cur")
          (move-file (str maildir file) (str maildir sink "/cur")))))))

(-main)

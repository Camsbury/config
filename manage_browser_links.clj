(require '[clojure.edn :as edn])
(require '[clojure.set :as set])
(require '[clojure.string :as str])
(require '[clojure.pprint :as pprint])

(def browser-links-path   "/home/monoid/Dropbox/lxndr/ref/")
(def browser-links        (str browser-links-path "browser-links.edn"))
(def browser-links-backup (str browser-links-path "browser-links-bak.edn"))

(defn entry->name->entry
  [{n :name :as entry}]
  [n entry])

(defn back-up-links [links]
  (spit browser-links-backup links))

(defn append-link
  "append a link to `browser-links`"
  [_ link-name url tags]
  (let [links (-> browser-links slurp edn/read-string)
        entry
        {:name link-name
         :url  url
         :tags
         (->>  (str/split tags #" ")
               (into #{} (map keyword)))}]
    (back-up-links links)
    (->> entry
         (conj links)
         (sort-by :name)
         (into [])
         pprint/pprint
         with-out-str
         (spit browser-links))))

(defn list-tags
  "list link tags"
  []
  (->> browser-links
       slurp
       edn/read-string
       (mapcat :tags)
       (into #{})
       sort
       (into [] (map name))))

(defn list-all
  "list all links"
  []
  (->> browser-links
       slurp
       edn/read-string
       (into {} (map entry->name->entry))))

(defn list-tagged
  "list links by tag"
  [tags]
  (let [tags (->>  (str/split tags #" ")
               (into #{} (map keyword)))]
    (->> browser-links
         slurp
         edn/read-string
         (into {}
               (comp
                (filter #(set/subset? tags (into #{} (:tags %))))
                (map entry->name->entry))))))

;;; TODO: implement nils
(case (first *command-line-args*)
  "append-link"
  (apply append-link *command-line-args*)

  "list-all"
  (list-all)

  "list-tags"
  (list-tags)

  "list-tagged"
  (list-tagged (second *command-line-args*))

  "remove-link"
  nil

  "tag-link"
  nil)


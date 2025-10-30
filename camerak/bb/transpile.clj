(ns transpile
  (:require
   [camel-snake-kebab.core :as csk]
   [clojure.string :as str]
   [clojure.edn :as edn]))

(def aliases
  (->> "./aliases.edn"
       slurp
       edn/read-string))

(def translation-map
  (let [hash "6dfe915e26d7147e6c2bed495d3b01cf5b21e6ec"
        raw-md
        (slurp
          (str
            "https://raw.githubusercontent.com/qmk/qmk_firmware/"
            hash
            "/docs/keycodes.md"))
        tables
        (->> raw-md
             (re-seq #"(?s)(\|Key[^\n]*\n(?:\|[^\n]*\n?)*)")
             (map first))
        ;; TODO: extract the documentation for each for easy lookup
        keycodes
        (->> tables
             (map str/split-lines)
             (mapcat #(drop 2 %))
             (mapcat (fn [line]
                       (let [[_ keycode aliases] (re-find #"^\|\s*`([^|]+?)(?:\([^\)]*\))*`\s*\|\s*([^|]*)\|" line)]
                         (->> aliases
                              (re-seq #"`([^`]+?)(?:\([^\)]*\))*`")
                              (map second)
                              (cons keycode)))))
             (remove #{"_______" "XXXXXXX"}))]
    (reduce
      (fn [acc kc]
        (assoc acc (csk/->kebab-case-keyword kc) kc))
      {}
      keycodes)))

(defn get-kc
  [translation-map kc]
  (get
    translation-map
    kc
    (cond
      (keyword? kc)
      (csk/->SCREAMING_SNAKE_CASE_STRING kc)

      (string? kc)
      (str "\"" kc "\"")

      :else
      kc)))

(defn map-keycode
  [layer-map]
  (fn map-it [kc]
    (cond
      (sequential? kc)
      (str
        (get-kc translation-map (first kc))
        "("
        (->> kc
             rest
             (map map-it)
             (str/join ", "))
        ")")

      (contains? layer-map kc)
      (get layer-map kc)

      (contains? aliases kc)
      (->> kc
           (get aliases)
           (map-it))

      :else
      (get-kc translation-map kc))))

(defn map-hand
  [layer-map {:keys [main outer inner bottom thumb]}]
  (let [map-row #(mapv (map-keycode layer-map) %)
        t-top   (:top thumb)
        t-main  (:main thumb)
        t-inner (:inner thumb)]
    {:main   (mapv map-row main)
     :outer  (map-row outer)
     :inner  (map-row inner)
     :bottom (map-row bottom)
     :thumb  {:top   (map-row t-top)
              :main  (map-row t-main)
              :inner (map-row t-inner)}}))

(defn map-layer
  [layer-map {:keys [left right]}]
  {:left (map-hand layer-map left)
   :right (map-hand layer-map right)})

(defn left->array
  [{:keys [main outer inner bottom thumb]}]
  (reduce
   into
   []
   [[(first outer)]
    (first main)
    [(first inner)]
    [(second outer)]
    (second main)
    [(second inner)]
    [(nth outer 2)]
    (nth main 2)
    [(last outer)]
    (last main)
    [(last inner)]
    bottom
    (:top thumb)
    [(first (:inner thumb))]
    (:main thumb)
    [(second (:inner thumb))]]))

(defn right->array
  [{:keys [main outer inner bottom thumb]}]
  (reduce
   into
   []
   [[(first inner)]
    (first main)
    [(first outer)]
    [(second inner)]
    (second main)
    [(second outer)]
    (nth main 2)
    [(nth outer 2)]
    [(last inner)]
    (last main)
    [(last outer)]
    bottom
    (:top thumb)
    (:inner thumb)
    (:main thumb)]))

(defn layer->array
  [{:keys [left right]}]
  (into (left->array left) (right->array right)))

(defn compile-layer
  [layer-map {:keys [title layout]}]
  (str
   "  ["
   (get layer-map title)
   "] = LAYOUT_ergodox("
   (->> layout
        (map-layer layer-map)
        layer->array
        (str/join ", "))
   ")"))

(defn compile-keymap [keymap]
  (let [layer-map
        (->> keymap
             (map :title)
             (map vector (range))
             (reduce (fn [acc [v k]] (assoc acc k v)) {}))
        layers (map #(compile-layer layer-map %) keymap)]
    (str
     "const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {\n"
     (str/join ",\n" layers)
     "\n};")))

(defn execute! []
  (let [keymap-edn (slurp "./keymap.edn")
        compiled   (->> keymap-edn
                        edn/read-string
                        compile-keymap)
        keymap-c   (slurp "./keymap.c")]
    (->> compiled
         (str/replace keymap-c #"(?s)(const uint16_t PROGMEM keymaps\[\]\[MATRIX_ROWS\]\[MATRIX_COLS\] = \{[^}]+?\};)")
         (spit "./keymap.c"))
    (println "Transpiled edn to C")))

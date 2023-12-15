(def layout
  (slurp "keymap.edn"))

;; TODO: macros into the form
;; #define CHROME_INSPECT_M LGUI(LSFT(KC_C))

;; TODO: keymaps into the shape of that in keymap.c
;; TODO: compare

(spit "camerak.h" layout)

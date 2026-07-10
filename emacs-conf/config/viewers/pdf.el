;; -*- lexical-binding: t; -*-
(general-define-key
 :keymaps 'doc-view-mode-map
 [remap doc-view-scroll-up-or-next-page] #'hydra-leader/body
 [remap describe-mode] #'doc-view-previous-page
 "k"                   #'doc-view-previous-page
 "l"                   #'doc-view-next-page
 "n"                   #'doc-view-search-next-match
 "p"                   #'doc-view-search-previous-match
 "/"                   #'doc-view-search)

(provide 'config/viewers/pdf)

;; Keybinding file: `general-define-key' plus the doc-view commands and the
;; leader hydra it remaps to are all runtime forward-refs.  Suppress just the
;; unresolved class; every other class stays live.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

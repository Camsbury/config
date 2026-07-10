;; -*- lexical-binding: t; -*-
(require 'prelude)
;; defhydra/general-def macros come from here, so they expand in byte-compile
;; isolation instead of depending on the core/bindings hub.
(require 'core/definers)
(use-package alda-mode
  :mode "\\.alda\\'"
  :interpreter "alda")

(general-def 'normal alda-mode-map
 [remap ck/empty-mode-leader] #'hydra-alda/body)

(defhydra hydra-alda (:exit t)
  "alda-mode"
  ("l" #'alda-play-line "play line")
  ("f" #'alda-play-file "play file"))

(provide 'config/langs/alda)

;; use-package config + hydra: forward-refs deferred alda commands invoked only
;; at runtime.  Suppress just the unresolved class.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

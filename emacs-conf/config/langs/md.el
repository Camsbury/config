;; -*- lexical-binding: t; -*-
(require 'prelude)
;; defhydra/general-def macros come from here, so they expand in byte-compile
;; isolation instead of depending on the core/bindings hub.
(require 'core/definers)

(use-package markdown-mode)
(use-package grip-mode
  :after (markdown-mode))
(setq grip-command 'go-grip)
(setq grip-preview-in-webkit nil)
(setq grip-real-time-refresh nil)

;; gfm-mode-map inherits from markdown-mode-map, so this covers both; modes
;; with their own leader (e.g. eca-chat) shadow it in their child maps.
(general-def 'normal markdown-mode-map
 [remap ck/empty-mode-leader] #'hydra-md/body)

(defhydra hydra-md (:exit t)
  "markdown-mode"
  ("s" #'grip-start-preview   "start grip view")
  ("k" #'grip-stop-preview    "stop grip view")
  ("r" #'grip-restart-preview "restart grip view"))

(provide 'config/langs/md)

;; use-package config + hydra: forward-refs deferred grip commands invoked only
;; at runtime.  Suppress just the unresolved class.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

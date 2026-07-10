;; -*- lexical-binding: t; -*-
(require 'prelude)
;; defhydra/general-def/general-add-hook macros come from here, so they expand
;; in byte-compile isolation instead of depending on the core/bindings hub.
(require 'core/definers)
(use-package racket-mode)

(general-def 'normal racket-mode-map
 [remap ck/empty-mode-leader] #'hydra-racket/body
 )

(general-add-hook
 'racket-mode-hook
 (list
  'paredit-mode
  'lispyville-mode
  'flycheck-mode))

(defhydra hydra-racket (:exit t)
  "racket-mode"
 ("r" #'racket-repl                   "repl")
 ("l" #'racket-run-and-switch-to-repl "run and repl")
 ("t" #'racket-test                   "test"))

(provide 'config/langs/racket)

;; use-package config + hydra: forward-refs deferred racket commands and hydra
;; runtime helpers, invoked only at runtime.  Suppress the unresolved class.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

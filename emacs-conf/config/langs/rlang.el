;; -*- lexical-binding: t; -*-
(require 'prelude)
;; defhydra/general-def macros come from here, so they expand in byte-compile
;; isolation instead of depending on the core/bindings hub.
(require 'core/definers)
;; ess owns this keymap; declare so the general-def ref doesn't warn.
(declare-vars ess-r-mode-map)
(use-package ess)
(general-def 'normal ess-r-mode-map
  [remap ck/empty-mode-leader] #'hydra-r/body
  [remap ess-use-this-dir]  #'ess-eval-region-or-function-or-paragraph)

(defhydra hydra-r (:exit t)
  "ess-r-mode"
  ("b" #'essk-eval-buffer "eval buffer")
  ("l" #'ess-eval-line   "eval line")
  ("r" #'ess-eval-region "eval region"))

(provide 'config/langs/rlang)

;; use-package config + hydra: forward-refs ess commands and hydra-r/body,
;; invoked only at runtime.  Suppress just the unresolved class.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

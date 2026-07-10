;; -*- lexical-binding: t; -*-
(require 'prelude)
;; defhydra/general-def/general-add-hook macros come from here, so they expand
;; in byte-compile isolation instead of depending on the core/bindings hub.
(require 'core/definers)
(use-package go-mode)
(use-package company-go
  :after (company))

(general-def 'normal go-mode-map
 [remap ck/empty-mode-leader] #'hydra-go/body)

(setq gofmt-command "goimports")

(general-add-hook
 'go-mode-hook
 `(#'flycheck-mode
   #'company-mode
   ,(lambda () (add-hook 'before-save-hook 'gofmt-before-save))))


(defhydra hydra-go (:exit t)
  "go-mode"
  ("d" #'godef-jump "jump to def"))


(provide 'config/langs/go)

;; use-package config + hydra: forward-refs deferred go commands invoked only at
;; runtime.  Suppress just the unresolved class.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

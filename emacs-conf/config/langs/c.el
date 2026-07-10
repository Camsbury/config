;; -*- lexical-binding: t; -*-
(require 'prelude)
;; defhydra/general-def/general-add-hook macros come from here, so they expand
;; in byte-compile isolation instead of depending on the core/bindings hub.
(require 'core/definers)
;; cc-mode owns these; declare so the load-time setqs/keymap ref don't warn.
(declare-vars c-basic-offset c-basic-indent c-default-style c-mode-map)
(use-package company-c-headers
  :after (company))
(use-package reformatter)
(use-package astyle) ; ensure astyle is available

(setq c-basic-offset 2)
(setq c-basic-indent 2)
(setq c-default-style "linux")

(general-def 'normal c-mode-map
 [remap ck/empty-mode-leader] #'hydra-c/body)

(general-add-hook 'c-mode-hook
  (list
    (lambda ()
      (progn
        (setq company-backends (delete 'company-clang company-backends))
        (add-to-list 'company-backends 'company-c-headers)))
    'astyle-on-save-mode
    'flycheck-mode
    'eldoc-mode
    'rainbow-delimiters-mode))

(defhydra hydra-c (:exit t)
  "c-mode"
  ("m" #'man "man page"))

(provide 'config/langs/c)

;; use-package config + hydra: hydra-c/body is a runtime forward-ref.  Suppress
;; just the unresolved class.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

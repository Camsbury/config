;; -*- lexical-binding: t; -*-
(require 'prelude)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Evil

(use-package evil
  :init
  (setq evil-want-Y-yank-to-eol t
        evil-move-beyond-eol    t
        evil-want-keybinding    nil)
  :config
  (evil-mode)
  (add-to-list 'evil-emacs-state-modes 'dired-mode))
(use-package evil-collection)

(provide 'core/text)

;; use-package config file: `evil-mode' is evil's own entry point, loaded by
;; the same form at runtime.  Suppress just the unresolved class; every other
;; class stays live.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

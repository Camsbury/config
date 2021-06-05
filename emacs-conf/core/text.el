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

(provide 'core/text)

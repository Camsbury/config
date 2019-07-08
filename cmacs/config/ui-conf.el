(use-package smartparens-config)
(use-package general)

(column-number-mode)
(show-paren-mode)
;; (electric-pair-mode)
(smartparens-global-mode)
(global-auto-revert-mode)
(global-hl-line-mode)
(doom-modeline-init)

;; who wants pairs of *?
(sp-pair "*" nil :actions :rem)

;; open buffers in a vertical split!
(setq split-height-threshold nil)
(setq split-width-threshold 160)

(setq hl-todo-keyword-faces
      `(("TODO"  . ,(face-foreground 'warning))
        ("FIXME" . ,(face-foreground 'error))
        ("NOTE"  . ,(face-foreground 'success)))
      find-function-C-source-dir "<some-dir>/emacs/src"
      whitespace-line-column 80
      whitespace-style '(face trailing lines-tail))

(general-add-hook 'prog-mode-hook
  (list 'hl-todo-mode
        'whitespace-mode
        'rainbow-delimiters-mode
        'rainbow-mode
        'linum-mode
        'evil-smartparens-mode))

(provide 'ui-conf)

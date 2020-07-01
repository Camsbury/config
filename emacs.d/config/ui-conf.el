(use-package general)
(use-package doom-modeline)

(column-number-mode)
(show-paren-mode)
(electric-pair-mode)
(global-auto-revert-mode)
(global-hl-line-mode)
(doom-modeline-init)

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
        'direnv-mode))

(general-add-hook 'yaml-mode-hook
                  (list 'linum-mode))

(provide 'ui-conf)

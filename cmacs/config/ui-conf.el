(column-number-mode)
(show-paren-mode)
(electric-pair-mode)
(global-linum-mode)
(global-auto-revert-mode)

(setq hl-todo-keyword-faces
      `(("TODO"  . ,(face-foreground 'warning))
        ("FIXME" . ,(face-foreground 'error))
        ("NOTE"  . ,(face-foreground 'success))))
(setq
 whitespace-line-column 80
 whitespace-style '(face trailing lines-tail))
(general-add-hook 'prog-mode-hook
  (list 'hl-todo-mode
        'whitespace-mode))

(provide 'ui-conf)

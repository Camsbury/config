(column-number-mode)
(show-paren-mode)
(electric-pair-mode)
(global-linum-mode)
(global-auto-revert-mode)

(setq hl-todo-keyword-faces
      `(("TODO"  . ,(face-foreground 'warning))
        ("FIXME" . ,(face-foreground 'error))
        ("NOTE"  . ,(face-foreground 'success))))
(general-add-hook 'prog-mode-hook
  (list 'hl-todo-mode))

(provide 'ui-conf)

(use-package hl-todo
  :init
  (setq hl-todo-keyword-faces
        `(("TODO"  . ,(face-foreground 'warning))
          ("FIXME" . ,(face-foreground 'error))
          ("NOTE"  . ,(face-foreground 'success)))))

(setq tab-width 2)
(setq-default indent-tabs-mode nil)
(setq-default fill-column 80)
(general-add-hook 'before-save-hook 'whitespace-cleanup)

(column-number-mode)
(show-paren-mode)
(electric-pair-mode)
(global-auto-revert-mode)
(global-hl-line-mode)

;; open buffers in a vertical split!
(setq split-height-threshold nil)
(setq split-width-threshold 160)
(setq
 find-function-C-source-directory (getenv "EMACS_C_SOURCE_PATH")
 whitespace-line-column 80
 whitespace-style '(face trailing lines-tail))

(general-add-hook 'prog-mode-hook
  (list 'hl-todo-mode
        'whitespace-mode
        'rainbow-delimiters-mode
        'rainbow-mode
        'linum-mode))

(provide 'core/prog)

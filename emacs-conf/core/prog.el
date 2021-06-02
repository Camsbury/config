(use-package flycheck)
(use-package flycheck-popup-tip)
(use-package origami)

(use-package hl-todo
  :init
  (setq hl-todo-keyword-faces
        `(("TODO"  . ,(face-foreground 'warning))
          ("FIXME" . ,(face-foreground 'error))
          ("NOTE"  . ,(face-foreground 'success))
          ("CLEAN" . "#7cb8bb")
          ("USEIT" . "#dc8cc3"))))

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
(setq split-height-threshold nil
      split-width-threshold 160)

(setq
 whitespace-line-column 80
 whitespace-style '(face trailing lines-tail))

(general-add-hook 'prog-mode-hook
  (list 'hl-todo-mode
        'whitespace-mode
        'rainbow-delimiters-mode
        'rainbow-mode
        'display-line-numbers-mode))

(provide 'core/prog)

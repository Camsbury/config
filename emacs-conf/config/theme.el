(use-package doom-modeline
  :config (doom-modeline-init))
(use-package doom-themes
  :config (load-theme 'doom-molokai t))
(use-package rainbow-delimiters)
(use-package rainbow-mode)

;; theme
(set-frame-font "Go Mono 10" nil t)

(if (> (x-display-pixel-width) 1600)
    (setq normal-font-height 100)
  (setq normal-font-height 110))

(set-face-attribute 'default nil :height normal-font-height)

(provide 'config/theme)

(require 'prelude)

(use-package doom-modeline
  :config (doom-modeline-mode))
(use-package doom-themes
  :config (load-theme 'doom-molokai t))
(use-package rainbow-delimiters)
(use-package rainbow-mode)

;; theme
(set-frame-font "Go Mono 10" nil t)

(defvar normal-font-height)
(if (> (x-display-pixel-width) 1600)
    (setq normal-font-height 100)
  (setq normal-font-height 110))

(set-face-attribute 'default nil :height normal-font-height)

(provide 'config/theme)

(comment
 (load-theme 'doom-molokai t)
 (load-theme 'doom-acario-dark t))

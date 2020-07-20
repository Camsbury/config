(use-package doom-themes
  :config
  (load-theme 'doom-molokai t))

(set-default-font "Go Mono 10")

(if (> (x-display-pixel-width) 1600)
    (setq normal-font-height 90)
  (setq normal-font-height 70))

(set-face-attribute 'default nil :height normal-font-height)

(add-to-list 'after-make-frame-functions #'my-theme)

(provide 'theme-conf)

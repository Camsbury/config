(load-theme 'doom-molokai t)

(setq normal-font-height 70)
(set-default-font "Go Mono 10")

(if (> (x-display-pixel-width) 1600)
    (setq normal-font-height 90)
  (setq normal-font-height 70))

(set-face-attribute 'default nil :height normal-font-height)

(provide 'theme-conf)

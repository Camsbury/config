(load-theme 'doom-molokai t)

(setq normal-font-height 70)

(if (> (x-display-pixel-width) 1600)
    (progn
      (set-default-font "Go Mono 6")
      (set-face-attribute 'default nil :height normal-font-height))
  (set-default-font "Go Mono 8"))


(provide 'theme-conf)

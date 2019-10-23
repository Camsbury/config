(load-theme 'doom-molokai t)

(setq normal-font-height 50)

(if (> (x-display-pixel-width) 1600)
    (progn
      (set-default-font "Roboto Mono 6")
      (set-face-attribute 'default nil :height normal-font-height))
  (set-default-font "Roboto Mono 8"))


(provide 'theme-conf)

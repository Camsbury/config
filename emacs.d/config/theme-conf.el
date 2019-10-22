(load-theme 'doom-molokai t)
(if (> (x-display-pixel-width) 1600)
    (progn
      (set-default-font "Roboto Mono 6")
      (set-face-attribute 'default nil :height 60))
  (set-default-font "Roboto Mono 8"))


(provide 'theme-conf)

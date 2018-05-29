(column-number-mode)
(show-paren-mode)
(electric-pair-mode)
(global-linum-mode)
(global-auto-revert-mode)
(ivy-mode)
(evil-mode)
(recentf-mode)
(projectile-mode)
(rainbow-delimiters-mode) ;; make these two apply to all modes (no global)
(rainbow-identifiers-mode)
(load-theme 'doom-molokai t)

;; scroll settings
(setq redisplay-dont-pause t
      scroll-margin 1
      scroll-step 1
      scroll-conservatively 10000
      scroll-preserve-screen-position 1)

(provide 'ui-conf)

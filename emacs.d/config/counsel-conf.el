(ivy-mode)
(recentf-mode)
(projectile-mode)
(minibuffer-electric-default-mode)

;; Remove the initial carat from searches
(setq ivy-initial-inputs-alist nil
      ivy-format-function 'ivy-format-function-line)
(setq counsel-find-file-ignore-regexp "[~\#]$")
(custom-set-faces
 '(ivy-current-match ((t (:background "#3a403a")))))

(provide 'counsel-conf)

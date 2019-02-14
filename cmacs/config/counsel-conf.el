(ivy-mode)
(recentf-mode)
(projectile-mode)

;; Remove the initial carat from searches
(setq ivy-initial-inputs-alist nil
      ivy-format-function 'ivy-format-function-line)
(setq counsel-find-file-ignore-regexp "[~\#]$")
(custom-set-faces
 '(ivy-current-match ((t (:background "#3a403a")))))
(setq counsel-rg-base-command
      "rg -i -g !.git --no-heading --line-number --hidden --color never %s .")

(provide 'counsel-conf)

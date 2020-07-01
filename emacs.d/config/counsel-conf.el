(use-package counsel)
(use-package counsel-projectile)

(ivy-mode)
(all-the-icons-ivy-rich-mode 1)
(ivy-rich-mode 1)
(recentf-mode)
(projectile-mode)
(minibuffer-electric-default-mode)

;; Remove the initial carat from searches
(setq ivy-initial-inputs-alist nil
      ivy-format-function 'ivy-format-function-line)
(setq ivy-rich-path-style 'abbrev)
(setq counsel-find-file-ignore-regexp "[~\#]$")
(custom-set-faces
 '(ivy-current-match ((t (:background "#3a403a")))))

(provide 'counsel-conf)

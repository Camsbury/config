(use-package ivy
  :init
  ;; Remove the initial carat from searches
  (setq ivy-initial-inputs-alist nil
        ivy-format-function 'ivy-format-function-line)
  (setq counsel-find-file-ignore-regexp "[~\#]$")
  (custom-set-faces
    '(ivy-current-match ((t (:background "#3a403a")))))
  :config
  (ivy-mode)
  (recentf-mode)
  (projectile-mode)
  (minibuffer-electric-default-mode)
  :defer t)

(provide 'counsel-conf)

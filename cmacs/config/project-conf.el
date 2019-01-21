(projectile-discover-projects-in-directory "~/projects")
(setq projectile-globally-ignored-file-suffixes '("~" "#"))

;; required to use counsel-projectile
(setq projectile-keymap-prefix (kbd "C-c C-p"))

(provide 'project-conf)

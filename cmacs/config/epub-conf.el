(add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))
(setq nov-text-width 80)
(general-add-hook 'nov-mode-hook
                  'evil-mode)

(provide 'epub-conf)

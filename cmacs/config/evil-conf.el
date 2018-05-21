(use-package evil
  :config
  (add-hook 'evil-mode-hook 'evil-surround-mode)
  (add-hook 'evil-mode-hook 'evil-commentary-mode))
(provide 'evil-conf)

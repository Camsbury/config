(use-package yaml-mode
  :init (general-add-hook 'yaml-mode-hook
                          (list 'display-line-numbers-mode)))

(provide 'config/langs/yaml)

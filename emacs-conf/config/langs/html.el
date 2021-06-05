(use-package prettier-js)
(general-add-hook 'html-mode-hook
                  (list 'flycheck-mode
                        'prettier-js-mode))

(provide 'config/langs/html)

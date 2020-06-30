(require 'prettier-js)
(general-add-hook 'html-mode-hook
                  (list 'flycheck-mode
                        'prettier-js-mode))

(provide 'langs/html-conf)

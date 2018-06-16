(require 'lsp-ui)

(general-add-hook 'lsp-mode-hook
                  (list 'lsp-ui-mode))

(provide 'lsp-conf)

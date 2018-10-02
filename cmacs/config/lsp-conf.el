(require 'lsp-ui)

(general-add-hook 'lsp-mode-hook
                  (list 'lsp-ui-mode))

(general-def
 :states  'normal
 :keymaps 'lsp-ui-imenu-mode-map
 "q" 'lsp-ui-imenu--kill)

(provide 'lsp-conf)

(require 'lsp-clients)
(require 'lsp-ui)
(require 'lsp-ui-flycheck)
(require 'company-lsp)

(general-add-hook 'lsp-mode-hook
                  (list #'lsp-ui-mode
                        (lambda () (add-to-list 'company-backends 'company-lsp))))
(with-eval-after-load 'lsp-mode
  (general-add-hook 'lsp-after-open-hook
                    (lambda () (lsp-ui-flycheck-enable 1))))

(general-def
 :states  'normal
 :keymaps 'lsp-ui-imenu-mode-map
 "q" 'lsp-ui-imenu--kill)

(provide 'lsp-conf)

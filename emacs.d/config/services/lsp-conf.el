(use-package lsp-clients)
(use-package lsp-ui)
(use-package lsp-ui-flycheck)
(use-package company-lsp)

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

(provide 'services/lsp-conf)

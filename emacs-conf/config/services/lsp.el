(use-package lsp-ui
  :after (lsp-mode))
(use-package lsp-ui-flycheck
  :after (lsp-ui))

(with-eval-after-load 'lsp-mode
  (general-add-hook 'lsp-after-open-hook
                    (lambda () (lsp-ui-flycheck-enable 1))))

(general-def
 :states  'normal
 :keymaps 'lsp-ui-imenu-mode-map
 "q" 'lsp-ui-imenu--kill)

(provide 'config/services/lsp)

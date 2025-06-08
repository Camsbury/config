(use-package typescript-mode
  :config
  (setq lsp-clients-typescript-server "typescript-language-server")
  (setq lsp-clients-typescript-server-args '("--stdio"))
  :hook
  (typescript-mode . lsp-deferred))

(provide 'config/langs/ts)

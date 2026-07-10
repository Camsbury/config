;; -*- lexical-binding: t; -*-
;; TODO: autoloads need looking into: no `:mode' and the `:hook' stub is
;; suppressed (lsp-deferred is already defined), so this never loads and
;; .ts files get no major mode.
(require 'prelude)
;; lsp-mode owns these; declare so the :config setqs don't warn.
(declare-vars lsp-clients-typescript-server lsp-clients-typescript-server-args)
(use-package typescript-mode
  :config
  (setq lsp-clients-typescript-server "typescript-language-server")
  (setq lsp-clients-typescript-server-args '("--stdio"))
  :hook
  (typescript-mode . lsp-deferred))

(provide 'config/langs/ts)

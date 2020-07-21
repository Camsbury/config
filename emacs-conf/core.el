(require 'use-package)

;; use keychain env
(use-package keychain-environment
  :config (keychain-refresh-environment))

(provide 'core)

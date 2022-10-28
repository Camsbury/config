(require 'core/env)

(use-package lastpass
  :config
  ;; was trying to access /bin/bash
  (setq lastpass-shell "bash")
  (setq lastpass-user user-email)
  (setq lastpass-trust-login t)
  (lastpass-auth-source-enable))

(provide 'config/services/lastpass)

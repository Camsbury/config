(use-package keychain-environment
  :config (keychain-refresh-environment))
(use-package direnv
  :config (direnv-mode))
(use-package prodigy
  :config
  (general-def 'normal prodigy-mode-map
    "s" #'prodigy-start
    "r" #'prodigy-restart
    "m" #'prodigy-mark
    "M" #'prodigy-mark-all
    "u" #'prodigy-unmark
    "U" #'prodigy-unmark-all
    "S" #'prodigy-stop))


(provide 'core/env)

(use-package company)
(use-package company-cabal
  :after (company))
(use-package company-c-headers
  :after (company))
(use-package company-go
  :after (company))
(use-package company-jedi
  :after (company))
(use-package company-postgresql
  :after (company))
(global-company-mode)

(provide 'autocomplete-conf)

(use-package emacsql :defer t)
(use-package emacsql-psql :defer t)
(use-package emacsql-sqlite :defer t)
(use-package sqlup-mode)
(use-package company-postgresql
  :after (company))

(provide 'config/langs/sql)

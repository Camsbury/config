(use-package emacsql)
(use-package emacsql-psql)
(use-package emacsql-sqlite
  :config
  (setq emacsql-sqlite-executable
        (let ((ver (pkg-info-package-version "emacsql-sqlite")))
          (locate-file
           "emacsql-sqlite"
           (list
            (concat
             (->> "cmacs-load-path"
                  (shell-command-to-string)
                  (replace-regexp-in-string "\n$" ""))
             "/elpa/emacsql-sqlite-"
             (number-to-string (car ver))
             "."
             (number-to-string (cadr ver))
             "/sqlite/"))
           exec-suffixes
           1))))
(use-package sqlup-mode)
(use-package company-postgresql
  :after (company))

(provide 'config/langs/sql)

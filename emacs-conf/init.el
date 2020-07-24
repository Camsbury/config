(require 'init-options)
;; setup use-package
(setq package-load-list
      '((bind-key t)
        (use-package t)))
(package-initialize)
(require 'use-package)
(require 'prelude)
(require 'core)
(require 'config)

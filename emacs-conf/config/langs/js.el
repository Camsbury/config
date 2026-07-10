;; -*- lexical-binding: t; -*-
(require 'prelude)
;; css-mode owns css-indent-offset; general owns general-add-hook.  Declare so
;; the load-time setq and hook setups don't warn.
(declare-vars css-indent-offset)
(declare-functions "general" general-add-hook)
(use-package prettier-js)
(use-package rjsx-mode)
(use-package js2-mode)
(use-package tree-mode) ;; for json navigator
(use-package json-navigator)

(setq js-indent-level 2)
(setq js2-basic-offset 2)
(setq css-indent-offset 2)

(setq js2-mode-show-parse-errors nil)
(setq js2-mode-show-strict-warnings nil)
(add-to-list 'auto-mode-alist '("\\.js\\'" . rjsx-mode))

;; All the prettiers
(general-add-hook 'css-mode-hook
                  (list 'prettier-js-mode))
(general-add-hook 'json-mode-hook
                  (list 'prettier-js-mode))
(general-add-hook 'js2-mode-hook
                  (list 'prettier-js-mode))

(general-add-hook 'js-mode-hook
                  (list 'flycheck-mode
                        'prettier-js-mode))

(provide 'config/langs/js)

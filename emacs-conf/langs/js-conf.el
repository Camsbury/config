(use-package prettier-js)

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

(provide 'langs/js-conf)

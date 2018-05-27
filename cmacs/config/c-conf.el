(setq c-basic-offset 4)
(setq c-basic-indent 4)
(general-add-hook 'c-mode-hook
                  (list 'irony-mode
                        'flycheck-mode
                        'flycheck-irony-setup
                        'eldoc-mode
                        'irony-eldoc
                        'rainbow-delimiters-mode
                        'rainbow-identifiers-mode))

(provide 'c-conf)

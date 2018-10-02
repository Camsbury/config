(require 'lsp-python)
(require 'lsp-conf)

(general-add-hook 'python-mode-hook
                  (list 'lsp-python-enable
                        'lsp-ui-peek-mode
                        'yapf-mode
                        'flycheck-mode
                        (lambda () (general-add-hook
                                    'before-save-hook 'yapfify-buffer))))

(my-mode-leader-def
 :states  'normal
 :keymaps 'python-mode-map
 "f" 'lsp-ui-peek-find-references
 "n" 'lsp-rename
 "r" 'lsp-restart-workspace
 "i" 'lsp-ui-imenu)

(provide 'python-conf)

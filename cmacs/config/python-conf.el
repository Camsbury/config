(if (string-equal system-type "gnu/linux")
    (require 'lsp-clients))
(require 'lsp-conf)

(general-add-hook 'python-mode-hook
                  (list (if (string-equal system-type "darwin")
                            'lsp-python
                            'lsp-mode)
                        'yapf-mode
                        'flycheck-mode))

                        ;; 'lsp-ui-peek-mode

(general-add-hook 'before-save-hook
                  (lambda ()
                    (when (eq major-mode 'python-mode)
                      yapfify-buffer)))

(my-mode-leader-def
 :states  'normal
 :keymaps 'python-mode-map
 "f" 'lsp-ui-peek-find-references
 "n" 'lsp-rename
 "r" 'lsp-restart-workspace
 "i" 'lsp-ui-imenu)

(provide 'python-conf)

(require 'bindings-conf)

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


(general-def 'normal python-mode-map
 [remap empty-mode-leader] #'hydra-python/body
 )

(defhydra hydra-python (:exit t)
  "python-mode"
 ("f" 'lsp-ui-peek-find-references "find references")
 ("n" 'lsp-rename                  "rename variable")
 ("r" 'lsp-restart-workspace       "restart lsp")
 ("i" 'lsp-ui-imenu                "lsp imenu"))

(provide 'python-conf)

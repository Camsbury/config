(require 'bindings-conf)

(if (string-equal system-type "gnu/linux")
    (require 'lsp-clients))
(if (string-equal system-type "darwin")
    (require 'lsp-python))
(require 'lsp-conf)

(general-add-hook 'python-mode-hook
                  (list (if (string-equal system-type "darwin")
                            'lsp-python-enable
                            'lsp-mode)
                        'yapf-mode
                        'flycheck-mode)
                  (lambda () (make-local-variable 'hydra-leader/keymap) (define-key hydra-leader/keymap (kbd "m") 'hydra-python/body)))

                        ;; 'lsp-ui-peek-mode

(general-add-hook 'before-save-hook
                  (lambda ()
                    (when (eq major-mode 'python-mode)
                      (yapfify-buffer))))


(general-def 'normal python-mode-map
 [remap empty-mode-leader] #'hydra-python/body
 )

(defun python-narrow-defun ()
  "Narrows to the current defun"
  (interactive)
  (python-mark-defun)
  (call-interactively 'narrow-and-zoom-in)
  (evil-exit-visual-state))

(defhydra hydra-python (:exit t)
  "python-mode"
 ("f" #'lsp-ui-peek-find-references "find references")
 ("n" #'lsp-rename                  "rename variable")
 ("r" #'lsp-restart-workspace       "restart lsp")
 ("i" #'lsp-ui-imenu                "lsp imenu")
 ("o" #'python-narrow-defun         "focus on def"))

(provide 'python-conf)

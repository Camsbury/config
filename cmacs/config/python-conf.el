(require 'bindings-conf)
(require 'functions-conf)

(flycheck-define-checker
    python-mypy ""
    :command ("mypy"
              "--python-version" "3.6"
              source-original)
    :error-patterns
    ((error line-start (file-name) ":" line ": error:" (message) line-end))
    :modes python-mode)
(add-to-list 'flycheck-checkers 'python-mypy t)
(flycheck-add-next-checker 'python-pylint 'python-mypy)

(general-add-hook 'python-mode-hook
                  (list
                        #'yapf-mode
                        #'flycheck-mode)
                  (lambda ()
                    (make-local-variable 'hydra-leader/keymap)
                    (define-key hydra-leader/keymap (kbd "m") 'hydra-python/body)
                    (setq py-indent-offset 4)
                    (setq flycheck-python-pylint-executable "pylint")
                    (setq flycheck-pylintrc "~/urbint/grid/backend/src/.pylintrc")))

(general-add-hook 'before-save-hook
                  (lambda ()
                    (when (eq major-mode 'python-mode)
                      (yapfify-buffer
                       py-isort-buffer))))


(general-def 'normal python-mode-map
 [remap empty-mode-leader] #'hydra-python/body)

(defun python-narrow-defun ()
  "Narrows to the current defun"
  (interactive)
  (save-mark-and-excursion
    (python-mark-defun)
    (call-interactively 'narrow-and-zoom-in)))

(defhydra hydra-python (:exit t)
  "python-mode"
 ;; ("f" #'lsp-ui-peek-find-references "find references")
 ;; ("n" #'lsp-rename                  "rename variable")
 ;; ("r" #'lsp-restart-workspace       "restart lsp")
 ;; ("i" #'lsp-ui-imenu                "lsp imenu")
 ("o" #'python-narrow-defun         "focus on def"))

(provide 'python-conf)

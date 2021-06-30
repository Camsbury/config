(use-package python)
(use-package yapfify
  :after (python))
(use-package pylint
  :after (python))
(use-package py-isort
  :after (python))
(use-package company-jedi
  :after (company))

(flycheck-define-checker
    python-mypy ""
    :command ("mypy" source-original)
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
                    (setq python-indent-offset 4)
                    (setq flycheck-python-pylint-executable "pylint")))


(general-def 'normal python-mode-map
 [remap empty-mode-leader] #'hydra-python/body)

(defun python-narrow-defun ()
  "Narrows to the current defun"
  (interactive)
  (save-mark-and-excursion
    (python-mark-defun)
    (call-interactively 'narrow-and-zoom-in)))

(defun create-or-restart-python ()
  (interactive)
  (when (get-buffer "*Python*")
      (let ((kill-buffer-query-functions nil))
        (kill-buffer "*Python*")))
  (run-python))

(defhydra hydra-python (:exit t)
  "python-mode"
  ("o" #'python-narrow-defun      "focus on def")
  ("r" #'create-or-restart-python "python repl")
  ("l" #'python-shell-send-buffer "run buffer in repl")
  ("L" #'python-shell-send-region "run region in repl"))

(provide 'config/langs/python)

(require 'prelude)
(require 'flycheck)
(require 'general)
(require 'hydra)

(use-package python)
(use-package yapfify
  :after (python))
(use-package pylint
  :after (python))
(use-package pydoc
  :after (python))
(use-package counsel-pydoc
  :after (pydoc))
(use-package pytest
  :after (python))
(use-package python-pytest
  :after (python))
(use-package py-isort
  :after (python))

(flycheck-define-checker
    python-mypy ""
    :command ("mypy" source-original)
    :error-patterns
    ((error line-start (file-name) ":" line ": error:" (message) line-end))
    :modes python-mode)
(add-to-list 'flycheck-checkers 'python-mypy t)
(flycheck-add-next-checker 'python-mypy 'python-pylint)

(customize-set-variable 'python-indent-guess-indent-offset nil)

(setq flycheck-python-pylint-executable "pylint")
(general-add-hook 'python-mode-hook
                  (list
                   #'yapf-mode
                   #'flycheck-mode))


(general-def 'normal python-mode-map
 [remap empty-mode-leader] #'hydra-python/body)

(defun python-narrow-defun ()
  "Narrows to the current defun."
  (interactive)
  (save-mark-and-excursion
    (python-mark-defun)
    (call-interactively 'narrow-and-zoom-in)))

(defun create-or-restart-python ()
  "Will create or restart a repl for python use."
  (interactive)
  (when (get-buffer "*Python*")
      (let ((kill-buffer-query-functions nil))
        (kill-buffer "*Python*")))
  (run-python))

(defun kill-python-repl ()
  "Kill the python repl"
  (interactive)
  (when (get-buffer "*Python*")
      (let ((kill-buffer-query-functions nil))
        (kill-buffer "*Python*"))))

(defhydra hydra-python (:exit t)
  "python-mode"
  ("h" #'pydoc-at-point-no-jedi   "pydoc")
  ("o" #'python-narrow-defun      "focus on def")
  ("r" #'create-or-restart-python "python repl")
  ("k" #'kill-python-repl         "kill python repl")
  ("l" #'python-shell-send-buffer "run buffer in repl")
  ("L" #'python-shell-send-region "run region in repl")
  ("t" #'pytest-module            "run pytest on buffer")
  ("N" #'pytest-all               "run all pytests"))

(provide 'config/langs/python)

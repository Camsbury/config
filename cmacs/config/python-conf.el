(use-package bindings-conf)
(use-package functions-conf)
(use-package yapfify)

;; /nix/store/4igq48l69gpfmjg0k2hjn5zk8iil6h7f-python3.6-yapf-0.27.0/bin/yapf

(defun yapfify-call-bin (input-buffer output-buffer start-line end-line)
  "Call process yapf on INPUT-BUFFER saving the output to OUTPUT-BUFFER.

Return the exit code.  START-LINE and END-LINE specify region to
format."
  (with-current-buffer input-buffer
    (call-process-region (point-min) (point-max) "/nix/store/rqspbns7n6fgqxk2wdhai3waijx2xi0v-python3-3.6.8-env/bin/yapf" nil output-buffer nil "-l" (concat (number-to-string start-line) "-" (number-to-string end-line)))))

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
 ("o" #'python-narrow-defun         "focus on def"))

(provide 'python-conf)

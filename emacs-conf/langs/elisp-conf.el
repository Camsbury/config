(eval-after-load 'dash '(dash-enable-font-lock))
(general-add-hook 'emacs-lisp-mode-hook
                  (list 'paredit-mode
                        'lispyville-mode
                        (lambda ()
                          (add-to-list
                           'imenu-generic-expression
                           '("Hydra" "defhydra[[:blank:]\n]+\\([^ ^\n]+\\)" 1)))))

(setq find-function-C-source-directory (getenv "EMACS_C_SOURCE_PATH"))


(general-def 'normal emacs-lisp-mode-map
 [remap empty-mode-leader] #'hydra-elisp/body)

(defun elisp-narrow-defun ()
  "Narrows to the current defun"
  (interactive)
  (save-mark-and-excursion
    (mark-defun)
    (call-interactively 'narrow-and-zoom-in)))

(defhydra hydra-elisp (:exit t)
  "elisp-mode"
 ("l" #'eval-buffer         "eval buffer")
 ("o" #'elisp-narrow-defun  "focus on def")
 ("S" #'run-async-from-desc "run async command from description"))

(provide 'langs/elisp-conf)

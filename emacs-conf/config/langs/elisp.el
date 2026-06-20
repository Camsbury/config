;; -*- lexical-binding: t; -*-
(eval-after-load 'dash '(dash-enable-font-lock))
(general-add-hook 'emacs-lisp-mode-hook
                  (list 'paredit-mode
                        'lispyville-mode
                        'flycheck-mode
                        (lambda ()
                          (add-to-list
                           'flycheck-disabled-checkers
                           'emacs-lisp-checkdoc)
                          (add-to-list
                           'imenu-generic-expression
                           '("Hydra" "defhydra[[:blank:]\n]+\\([^ ^\n]+\\)" 1)))))

(setq find-function-C-source-directory (getenv "EMACS_C_SOURCE_PATH"))


(general-def 'normal emacs-lisp-mode-map
 [remap ck/empty-mode-leader] #'hydra-elisp/body)

(defun ck/elisp-narrow-defun ()
  "Narrows to the current defun"
  (interactive)
  (save-mark-and-excursion
    (mark-defun)
    (call-interactively 'ck/narrow-and-zoom-in)))

(defhydra hydra-elisp (:exit t)
  "elisp-mode"
  ("a" #'apropos             "search symbols")
  ("l" #'eval-buffer         "eval buffer")
  ("o" #'ck/elisp-narrow-defun  "focus on def")
  ("p" #'eval-defun          "eval outer sexp")
  ("S" #'ck/run-async-from-desc "run async command from description"))

(provide 'config/langs/elisp)

;; -*- lexical-binding: t; -*-
;; Flycheck byte-compiles each file in a fresh subprocess.  By default that
;; subprocess starts with an empty `load-path', so every `require' (packages,
;; elisp libs, and our own `provide'd sibling features) fails and cascades into
;; spurious "not known to be defined" / "free variable" warnings.  `inherit'
;; hands the checker this session's `load-path' so those requires resolve; the
;; residual warnings are then the real ones (dependencies a file uses without
;; requiring), which the per-file `require' + `declare-functions' work targets.
(setq flycheck-emacs-lisp-load-path 'inherit)

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

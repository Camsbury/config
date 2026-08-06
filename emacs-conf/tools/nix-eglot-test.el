;; -*- lexical-binding: t; -*-
;;; Regression checks for Nix Eglot and formatting support.

(require 'ert)
(require 'cl-lib)
(require 'config/langs/nix)

(defvar aggressive-indent-mode)

(ert-deftest ck/nix-selects-nixd-for-eglot ()
  (should (equal '("nixd")
                 (alist-get 'nix-mode eglot-server-programs))))

(ert-deftest ck/nix-enables-eglot-and-buffer-local-formatting ()
  (with-temp-buffer
    (let ((aggressive-indent-mode t)
          eglot-started
          aggressive-indent-argument)
      (cl-letf (((symbol-function 'eglot-ensure)
                 (lambda () (setq eglot-started t)))
                ((symbol-function 'aggressive-indent-mode)
                 (lambda (argument)
                   (setq aggressive-indent-argument argument))))
        (ck/nix-enable-eglot-and-formatting))
      (should eglot-started)
      (should (= -1 aggressive-indent-argument))
      (should (local-variable-p 'before-save-hook))
      (should (memq #'ck/nix-format-buffer before-save-hook)))))

(ert-deftest ck/nix-format-buffer-runs-nixfmt-with-stdin-argument ()
  (with-temp-buffer
    (insert "unformatted")
    (let (process-args)
      (cl-letf (((symbol-function 'executable-find)
                 (lambda (_program) "/fake/nixfmt"))
                ((symbol-function 'call-process-region)
                 (lambda (_start _end _program _delete destination _display
                          &rest args)
                   (setq process-args args)
                   (with-current-buffer (car destination)
                     (insert "formatted\n"))
                   0)))
        (ck/nix-format-buffer))
      (should (equal '("-") process-args))
      (should (equal "formatted\n" (buffer-string))))))

(ert-deftest ck/nix-format-failure-does-not-signal-or-change-buffer ()
  (with-temp-buffer
    (insert "original")
    (let (reported)
      (cl-letf (((symbol-function 'executable-find)
                 (lambda (_program) "/fake/nixfmt"))
                ((symbol-function 'call-process-region)
                 (lambda (_start _end _program _delete destination _display
                          &rest _args)
                   (with-temp-file (cadr destination)
                     (insert "broken input\n"))
                   1))
                ((symbol-function 'message)
                 (lambda (format-string &rest args)
                   (setq reported (apply #'format format-string args)))))
        (ck/nix-format-buffer))
      (should (equal "original" (buffer-string)))
      (should (equal "nixfmt failed: broken input" reported)))))

(provide 'nix-eglot-test)

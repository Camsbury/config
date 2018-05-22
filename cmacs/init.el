;; initialize installed packages for configuration
(package-initialize)

(setq load-path
      (cons "~/.emacs.d/config" load-path))

(setq initial-buffer-choice "*scratch*")
;; (setq initial-major-mode 'emacs-lisp-mode) - why doesn't this work

(require 'config)

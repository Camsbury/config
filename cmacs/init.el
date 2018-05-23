;; initialize installed packages for configuration
(package-initialize)

(setq load-path
      (cons "~/.emacs.d/config" load-path))

(setq initial-buffer-choice t)

(add-hook 'after-init-hook (lambda () (require 'config)))

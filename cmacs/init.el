;; initialize installed packages for configuration
(package-initialize)

 (setq load-path
       (cons "~/.emacs.d/config" load-path))

(require 'config)

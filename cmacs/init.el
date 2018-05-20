;; initialize installed packages for configuration
(package-initialize)

 (setq load-path
       (cons "~/.emacs.d/config" load-path))

(require 'functions)
(require 'bindings)

;; Global setup
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(column-number-mode)
(show-paren-mode)
(electric-pair-mode)
(ivy-mode)
(evil-mode)

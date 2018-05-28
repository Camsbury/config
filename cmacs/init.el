;; initialize installed packages for configuration
(package-initialize)

(setq load-path
      (cons "~/.emacs.d/config" load-path))

(setq initial-buffer-choice t)
(setq auto-window-vscroll nil)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(add-hook 'after-init-hook (lambda () (require 'config)))

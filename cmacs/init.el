;; initialize installed packages for configuration
(package-initialize)

(setq load-path
      (cons "~/.emacs.d/config" load-path))
(when (memq window-system '(ns))
  (exec-path-from-shell-initialize)
  (setq mac-command-modifier 'meta
        mac-option-modifier 'super))
(when (memq window-system '(x))
  (keychain-refresh-environment))

(setq initial-buffer-choice t)
(setq auto-window-vscroll nil)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(require 'use-package)
(use-package benchmark-init)
(add-hook 'after-init-hook
          (lambda ()
            (use-package config
                     :load-path "config/config.el"))
          'benchmark-init/deactivate)
(put 'narrow-to-region 'disabled nil)

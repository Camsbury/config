;; setup use-package
(setq package-load-list '((benchmark-init t)
                          (bind-key t)
                          (use-package t)))
(package-initialize)
(require 'use-package)

(require 'benchmark-init)
(benchmark-init/activate)

;; use keychain env
(use-package keychain-environment
  :config (keychain-refresh-environment))

;; remove extraneous visual components
(setq initial-buffer-choice t)
(setq auto-window-vscroll nil)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; enable narrowing
(put 'narrow-to-region 'disabled nil)

;; load config
(setq load-path
      (cons "~/.emacs.d/config" load-path))
(when (load "private-init.el")
 (use-package private-init))
(add-hook 'after-init-hook
          (lambda ()
            (use-package config)
            (benchmark-init/deactivate)))

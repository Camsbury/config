;; setup use-package
(setq package-load-list '((bind-key t)
                          (use-package t)))

;; remove extraneous visual components
(setq auto-window-vscroll nil)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; start with scratch buffer
(setq initial-buffer-choice t)

;; enable narrowing
(put 'narrow-to-region 'disabled nil)

;; don't pollute this file with custom values
(setq custom-file (concat user-emacs-directory "custom.el"))
(load custom-file 'noerror)

;; (package-initialize)
(add-hook 'after-init-hook
          (lambda () (require 'core)))
(add-hook 'emacs-startup-hook
          (lambda () (require 'config)))
;; (when (load "private-init.el")
;;  (require private-init))

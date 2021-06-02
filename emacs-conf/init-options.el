;; remove extraneous visual components
(setq auto-window-vscroll nil)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; start with scratch buffer
(setq initial-buffer-choice t)

;; don't litter backup files
(setq make-backup-files nil)

;; scroll options
(setq redisplay-dont-pause t
      scroll-margin 1
      scroll-step 1
      scroll-conservatively 10000
      scroll-preserve-screen-position 1)

;; enable narrowing
(put 'narrow-to-region 'disabled nil)

;; save custom values
(setq custom-file (concat user-emacs-directory "custom.el"))
(load custom-file 'noerror)
(defun custom-file (&optional no-error)
  (file-chase-links custom-file))

(provide 'init-options)

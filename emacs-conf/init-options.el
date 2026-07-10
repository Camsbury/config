;; remove extraneous visual components  -*- lexical-binding: t; -*-
(setq auto-window-vscroll nil)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; start with scratch buffer
(setq initial-buffer-choice t)

;; don't litter backup files
(setq make-backup-files nil)

;; scroll options
(setq scroll-margin 1
      scroll-step 1
      scroll-conservatively 10000
      scroll-preserve-screen-position 1)

;; enable narrowing
(put 'narrow-to-region 'disabled nil)

;; Old-style `defadvice' (pcre2el, pulled in by magit-todos, advises
;; align-regexp and friends) logs "ad-handle-definition: '<fn>' got
;; redefined" whenever an advised function is later redefined.  Purely
;; informational; accept silently (Doom sets the same).
(setq ad-redefinition-action 'accept)

;; save custom values
(setq custom-file (concat user-emacs-directory "custom.el"))
(load custom-file 'noerror)
;; The `custom-file' FUNCTION (cus-edit) decides where Custom saves; override
;; it so saves follow the symlink to the repo copy instead of clobbering it.
(declare-function custom-file "cus-edit" (&optional no-error))
(defun ck/force-custom-file (&optional _no-error)
  "Return `custom-file' with symlinks resolved, for Custom saves."
  (file-chase-links custom-file))
(advice-add #'custom-file :override #'ck/force-custom-file)

(provide 'init-options)

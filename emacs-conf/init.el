;; -*- lexical-binding: t; -*-
(setq gc-cons-threshold most-positive-fixnum)

;; Defer `file-name-handler-alist' for the duration of startup, mirroring the
;; GC deferral above.  Every `load'/`require' matches each file name against
;; every handler in this alist (TRAMP, jka-compr for gz, etc.); emptying it
;; avoids that scan across the hundreds of files pulled in below.  Safe here
;; because the whole config is plain, local .el/.elc (nothing loaded during
;; init needs a handler).  Restored once Emacs is up, merging in any handlers a
;; startup package registered so we do not clobber them.
(defvar ck--file-name-handler-alist file-name-handler-alist
  "Saved `file-name-handler-alist', restored on `emacs-startup-hook'.")
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist
                  (delete-dups (append file-name-handler-alist
                                       ck--file-name-handler-alist))))
          ;; Depth 100: run after other startup-hook functions, which thus
          ;; still benefit from the empty alist.
          100)

(require 'init-options)
;; set up use-package
(customize-set-variable 'package-load-list
                        '((bind-key t)
                          (use-package t)))
(package-initialize)
(require 'prelude)
(require 'core)
(require 'config)
;; Steady-state GC. Agents (ECA) cons hard via JSON parsing + fontification
;; of streamed output; a small threshold means GC pauses fire *inside*
;; redisplay and stall every workspace frame. 128MB keeps GC out of the hot
;; path. See config/performance.el for the redisplay-side tuning.
(setq gc-cons-threshold (* 128 1024 1024)
      gc-cons-percentage 0.2)

;; initialize workspaces
(dolist (i (number-sequence 0 9))
  (exwm-workspace-switch-create i))
(exwm-workspace-switch 1)

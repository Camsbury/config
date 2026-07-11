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
;; redisplay and stall every workspace frame. `ck/gc-idle-install' holds the
;; threshold high (256MB) so GC rarely fires mid-command, and forces one
;; collection after a short idle so the ~150ms pause lands off the hot path
;; (with an EXWM gate so it never stutters a focused X app). This runs here,
;; last during boot, so its `gc-cons-threshold' is the authoritative one. See
;; config/performance.el for the machinery and the redisplay-side tuning.
(setq gc-cons-percentage 0.2)
(ck/gc-idle-install)

;; Become the window manager only on a graphical X login session.  On a plain
;; TTY (`ck/wm-session-p' nil) EXWM cannot connect to X, so we skip activation
;; and the config runs editor-only.  The whole tree is already WM-free at load
;; time (tools/wm-free-check.sh); this gate is the one place the WM turns on.
;; The activation body (start EXWM, create workspaces) lives in `ck/enable-wm'
;; in core/desktop.el.  TTY-vs-WM dispatch seam: decision 0016.
(when (ck/wm-session-p)
  (ck/enable-wm))

;; Boot file: compiling it loads the whole tree, and packages that
;; byte-compile lambdas while loading (org-ql, pcre2el, vertico-posframe)
;; report their nested "might not be defined" noise against this file.
;; Suppress just the unresolved class; every other class stays live.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

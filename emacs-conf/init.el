;; -*- lexical-binding: t; -*-
(setq gc-cons-threshold most-positive-fixnum)

;; Every `load'/`require' matches each file name against every handler in this
;; alist (TRAMP, jka-compr for gz, etc.).  Emptying it for startup skips that
;; scan across the hundreds of files pulled in below, and is safe because the
;; whole config is plain local .el/.elc.  The restore merges in any handler a
;; startup package registered.
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
(customize-set-variable 'package-load-list
                        '((bind-key t)
                          (use-package t)))
(package-initialize)
(require 'prelude)
(require 'core)
(require 'config)
;; Steady-state GC.  `ck/gc-idle-install' holds `gc-cons-threshold' high so GC
;; rarely fires mid-command, and forces one collection after a short idle so
;; the pause lands off the redisplay path.  It runs here, last during boot, so
;; its threshold is the authoritative one.  See config/performance.el for the
;; machinery and the redisplay-side tuning.
(setq gc-cons-percentage 0.2)
(ck/gc-idle-install)

;; Become the window manager only on a graphical X login session.  On a plain
;; TTY EXWM cannot connect to X, so we skip activation and the config runs
;; editor-only.  This gate is the one place the WM turns on; the rest of the
;; tree is WM-free at load time (tools/wm-free-check.sh).  The activation body
;; is `ck/enable-wm' in core/desktop.el.
(when (ck/wm-session-p)
  (ck/enable-wm))

;; Boot file: compiling it loads the whole tree, and packages that
;; byte-compile lambdas while loading (org-ql, pcre2el, vertico-posframe)
;; report their nested "might not be defined" noise against this file.
;; Suppress just the unresolved class; every other class stays live.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

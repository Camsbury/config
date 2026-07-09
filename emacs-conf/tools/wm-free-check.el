;; -*- lexical-binding: t; -*-
;; The in-Emacs half of the WM-free load check (driven by wm-free-check.sh).
;;
;; Loads the FULL config, mirroring init.el's require order, in a normal
;; graphical Emacs that is NOT the window manager:
;;   - `exwm-wm-mode' is stubbed (becoming the WM is the one thing a non-WM
;;     Emacs cannot do; everything else must load).
;;   - `server-start' is stubbed so the check can never touch the live WM
;;     Emacs's server socket.
;;   - JIT native compilation is off so the check does not churn the shared
;;     eln-cache.
;;   - `kill-emacs-hook' is cleared before exit so save-on-exit hooks
;;     (recentf, savehist) cannot clobber the live session's state files.
;;
;; Writes PASS/FAIL plus a *Messages* tail (where use-package logs swallowed
;; errors) to $WM_FREE_CHECK_RESULT and exits 0/1.

(defvar wm-free-check--result-file
  (or (getenv "WM_FREE_CHECK_RESULT") "/tmp/cmacs-wm-free-check.txt"))

(defun wm-free-check--messages-tail ()
  "Last chunk of *Messages*: use-package logs swallowed errors there."
  (if (get-buffer "*Messages*")
      (with-current-buffer "*Messages*"
        (buffer-substring-no-properties
         (max (point-min) (- (point-max) 4000)) (point-max)))
    "(no *Messages*)"))

(condition-case e
    (progn
      (setq native-comp-jit-compilation nil)
      (fset 'server-start #'ignore)
      ;; mirror init.el from here down
      (require 'init-options)
      (customize-set-variable 'package-load-list
                              '((bind-key t) (use-package t)))
      (package-initialize)
      (require 'prelude)
      ;; load the exwm LIBRARY (fine without a WM), stub only the WM enable
      (require 'exwm)
      (fset 'exwm-wm-mode #'ignore)
      (require 'core)
      (require 'config)
      (setq kill-emacs-hook nil)
      (with-temp-file wm-free-check--result-file
        (insert "PASS: full config loaded WM-free\n"
                "\n--- messages tail ---\n"
                (wm-free-check--messages-tail)))
      (kill-emacs 0))
  (error
   (setq kill-emacs-hook nil)
   (with-temp-file wm-free-check--result-file
     (insert (format "FAIL: %S\n" e)
             "\n--- messages tail ---\n"
             (wm-free-check--messages-tail)))
   (kill-emacs 1)))

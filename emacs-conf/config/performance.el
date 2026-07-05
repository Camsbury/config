;; redisplay / responsiveness tuning  -*- lexical-binding: t; -*-
;;
;; Problem this addresses: under EXWM every workspace frame is an X-mapped
;; window that reports `visibility t', so Emacs redisplays buffers that are
;; churning on *inactive* workspaces too (e.g. an ECA agent streaming output
;; while you work elsewhere). Redisplay is single-threaded and per-frame, so
;; one busy buffer stalls the whole WM. We cannot cheaply suppress those
;; forced redisplays, so the strategy is: make each redisplay cheap, and keep
;; global GC pauses (from agent JSON parsing / fontification consing) out of
;; the redisplay path.
;;
;; The GC threshold itself lives in init.el (it is set last during boot, so a
;; module-level setq here would be clobbered).
(require 'prelude)

;; Long lines are the worst-case redisplay cost: a single minified blob, diff,
;; or log line from agent output turns every redisplay into an O(n) scan.
;; `so-long' detects them and strips the expensive machinery buffer-locally.
(global-so-long-mode 1)
(with-eval-after-load 'so-long
  ;; Extend so-long past its long-single-line detection to also trip on merely
  ;; LARGE files (huge logs, generated data): each line is fine on its own, but
  ;; the sheer count makes the expensive minor modes (font-lock, line numbers,
  ;; etc.) drag every redisplay. Needs `buffer-line-statistics' (Emacs 29+);
  ;; older Emacs keeps the stock long-line-only predicate.
  (when (fboundp 'buffer-line-statistics)
    (defvar ck/so-long-max-lines 20000
      "Line count above which a file buffer is handed to so-long.")
    (defun ck/so-long-p ()
      "`so-long-predicate' tripping on a long line OR a large line count."
      (let ((stats (buffer-line-statistics)))
        (or (> (cadr stats) so-long-threshold)            ; longest line width
            (and buffer-file-name
                 (> (car stats) ck/so-long-max-lines))))) ; total line count
    (setq so-long-predicate #'ck/so-long-p))
  ;; Keep these buffers editable. Use the minor-mode action (neuter the
  ;; expensive minor modes but keep the major mode) instead of the full
  ;; `so-long-mode', which swaps the major mode out, and drop the read-only
  ;; override so a large file is still a working buffer, just a lighter one.
  (setq so-long-action 'so-long-minor-mode)
  (setf (alist-get 'buffer-read-only so-long-variable-overrides nil t) nil))

;; Cheaper long-line layout. Safe here: this is an English + code config (LTR),
;; so the bidirectional paren algorithm and auto paragraph direction are pure
;; overhead.
(setq bidi-inhibit-bpa t)
(setq-default bidi-paragraph-direction 'left-to-right)

;; Keep fontification out of the redisplay storm: defer it briefly and let
;; pending keyboard input pre-empt it so typing stays responsive while a buffer
;; streams.
(setq jit-lock-defer-time 0.05
      redisplay-skip-fontification-on-input t)

;; Lighter scrolling + don't compact font caches (recreating them is costlier
;; than the memory they hold on this single, long-lived WM session).
(setq fast-but-imprecise-scrolling t
      inhibit-compacting-font-caches t)

(provide 'config/performance)

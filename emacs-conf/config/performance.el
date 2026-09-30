;; redisplay / responsiveness tuning  -*- lexical-binding: t; -*-
;;
;; Under EXWM every workspace frame is an X-mapped window that reports
;; `visibility t', so Emacs redisplays buffers churning on inactive workspaces
;; too, and redisplay is single-threaded: one busy buffer stalls the whole WM.
;; Those forced redisplays cannot be cheaply suppressed, so the strategy is to
;; make each redisplay cheap and keep GC pauses out of the redisplay path.
;;
;; The GC threshold itself lives in init.el (it is set last during boot, so a
;; module-level setq here would be clobbered).
(require 'prelude)

;; so-long owns these; forward-declare so setting them in the
;; `with-eval-after-load' below is not a free-variable warning.  `ck/so-long-p'
;; is defined further down inside that same deferred block, so declare it too.
(declare-vars so-long-threshold so-long-predicate so-long-action
              so-long-variable-overrides)
(declare-function ck/so-long-p "config/performance")

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

;; Idle GC (GCMH-style). This session's live heap is large, so EVERY full GC
;; costs ~140ms whatever the garbage volume: the cost is sweeping the live set.
;; Mid-interaction that pause is a whole-desktop freeze (Emacs is the WM). So
;; hold the threshold high, then force one collection after a short idle.
;;
;; EXWM gate: under char-mode, keystrokes to an X application go straight to
;; the X client and never reset Emacs's idle timer or run `post-command-hook'.
;; A naive idle GC would fire its pause while the user is actively using that
;; app, so we skip the collection when the selected buffer is an X window.
;;
;; Consing and interval gates: collecting on a pause that consed almost nothing
;; is pure stall, so the idle GC also needs `ck/gc-min-consed' allocated since
;; the last one and waits `ck/gc-min-interval' between collections.  The high
;; threshold is the backstop when consing outruns the gates.
(defvar ck/gc-idle-delay 4
  "Seconds of idle before an off-hot-path `garbage-collect'.")

(defvar ck/gc-high-threshold (* 256 1024 1024)
  "`gc-cons-threshold' held during activity so GC rarely fires mid-command.")

(defvar ck/gc-min-consed (* 64 1024 1024)
  "Approx bytes allocated since the last idle GC before another is worth it.
Every full GC here costs ~140ms regardless of garbage volume, so collecting on
a pause that consed almost nothing is pure stall; this gate skips those.")

(defvar ck/gc-min-interval 30
  "Minimum seconds between idle GCs: an upper bound on their frequency, and so
on the odds one lands on a notification glance or the moment you re-engage.")

(defvar ck/gc--idle-timer nil
  "One-shot idle timer, re-armed after each command; see `ck/gc-register'.")

(defvar ck/gc--last-time 0
  "`float-time' of the last idle GC (for `ck/gc-min-interval').")

(defvar ck/gc--last-use-counts nil
  "`memory-use-counts' snapshot at the last idle GC (for the consing gate).")

(defun ck/gc--bytes-consed-since ()
  "Approximate bytes allocated since the last idle GC.
`memory-use-counts' is cumulative and monotonic, so the weighted delta against
our last snapshot measures allocation regardless of any intervening GC."
  (if (null ck/gc--last-use-counts)
      most-positive-fixnum              ; no snapshot yet: allow the first GC
    (let ((now (memory-use-counts))
          (old ck/gc--last-use-counts)
          ;; rough 64-bit byte sizes per object kind, in memory-use-counts
          ;; order: conses floats vector-cells symbols string-chars intervals
          ;; strings
          (weights '(16 8 8 48 1 56 32))
          (total 0))
      (while (and now old weights)
        (setq total  (+ total (* (car weights) (- (car now) (car old))))
              now     (cdr now)
              old     (cdr old)
              weights (cdr weights)))
      total)))

(defun ck/gc-idle-collect ()
  "Collect garbage once the session has gone idle.
Skip the collection when the selected buffer is an `exwm-mode' X window, when
less than `ck/gc-min-consed' has been allocated since the last one, or when
the last one was under `ck/gc-min-interval' seconds ago.  The idle-GC
commentary in config/performance.el says why each gate is there."
  (unless (or (with-current-buffer (window-buffer (selected-window))
                (derived-mode-p 'exwm-mode))
              (< (- (float-time) ck/gc--last-time) ck/gc-min-interval)
              (< (ck/gc--bytes-consed-since) ck/gc-min-consed))
    (garbage-collect)
    (setq ck/gc--last-time (float-time)
          ck/gc--last-use-counts (memory-use-counts))))

(defun ck/gc-register ()
  "Re-arm the one-shot idle-GC timer. Run from `post-command-hook'.
Cancelling and rescheduling on every command yields exactly one collection per
idle stretch and never spins while the user is away."
  (when (timerp ck/gc--idle-timer)
    (cancel-timer ck/gc--idle-timer))
  (setq ck/gc--idle-timer
        (run-with-idle-timer ck/gc-idle-delay nil #'ck/gc-idle-collect)))

(defun ck/gc-idle-install ()
  "Enable idle GC: hold the threshold high and collect on idle. Idempotent.
Called from init.el after steady-state GC is configured so its
`gc-cons-threshold' is the authoritative last word during boot."
  (setq gc-cons-threshold ck/gc-high-threshold)
  (add-hook 'post-command-hook #'ck/gc-register))

(defun ck/gc-idle-uninstall ()
  "Disable idle GC (reverse of `ck/gc-idle-install')."
  (remove-hook 'post-command-hook #'ck/gc-register)
  (when (timerp ck/gc--idle-timer)
    (cancel-timer ck/gc--idle-timer)
    (setq ck/gc--idle-timer nil)))

(provide 'config/performance)

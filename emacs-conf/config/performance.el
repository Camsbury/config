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

;; Idle GC (GCMH-style). A single full-heap GC on this long-lived WM session
;; measures ~150ms; when it fires mid-interaction it is a hard redisplay stall,
;; i.e. a whole-desktop freeze (Emacs is the WM). Strategy: hold the threshold
;; high so GC rarely fires during activity, then force one collection after a
;; short idle so the pause lands off the interactive hot path.
;;
;; EXWM gate (the subtle part): under char-mode, keystrokes to an X application
;; go straight to the X client and never reset Emacs's idle timer or run
;; `post-command-hook'. A naive idle-GC would therefore fire its ~150ms pause
;; *while the user is actively using an X app* (game, browser), stuttering it.
;; So we skip the collection when the selected buffer is an X window; the high
;; threshold is the backstop until focus returns to an Emacs buffer and idles.
;;
;; ECA lifecycle: agents stream via process filters (no user input), so Emacs
;; goes "idle" during a stream lull with a normal (non-exwm) eca-chat buffer
;; selected, and the gate allows one idle-GC ~`ck/gc-idle-delay's in to sweep
;; the streaming garbage. A long uninterrupted stream leans on the threshold
;; backstop, which is the honest tradeoff.
;;
;; The threshold itself is set by `ck/gc-idle-install', called from init.el so
;; it stays the authoritative last word on GC during boot (a module-level setq
;; here would be clobbered, per the note at the top of this file).
;;
;; Consing gate: this session's live heap is large (multiple long-lived ECA
;; chats + big buffers), so EVERY full GC costs ~140ms no matter how much
;; garbage there is -- the cost is sweeping the live set, not the garbage.
;; Measured 2026-07-06: with a naive 4s idle-GC, ~14 collections fired over 8
;; minutes (one every ~35s), many collecting almost nothing, each a 140ms
;; pause that can collide with a notification glance or the user re-engaging.
;; So the idle GC only runs when a meaningful amount was actually allocated
;; since the last one (`ck/gc-min-consed') and not more often than
;; `ck/gc-min-interval'. Fewer collections -> fewer collision chances; the
;; 256MB threshold is the backstop if consing outruns the gate.
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
  "Collect garbage once the session has gone idle. Three gates keep the ~140ms
full-heap pause off the interactive path and rare:
 - skip when the selected buffer is an `exwm-mode' X window (under char-mode the
   user may be actively typing into it without resetting the idle timer, and a
   GC pause there would stutter the application);
 - skip when less than `ck/gc-min-consed' has been allocated since the last
   collection (nothing worth a full sweep);
 - skip when the last collection was under `ck/gc-min-interval' seconds ago."
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

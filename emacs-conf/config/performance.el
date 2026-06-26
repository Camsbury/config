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

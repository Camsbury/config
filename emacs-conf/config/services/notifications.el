;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'config/desktop/commands)

(use-package alert
  :config
  (setq
   alert-fade-time     180
   ;; D-Bus style (`notifications-notify'), NOT `libnotify'.  The libnotify
   ;; style shells out to notify-send via `call-process', i.e. it spawns a
   ;; SUBPROCESS from this Emacs.  Empirically that hitches a focused fullscreen
   ;; client (game): A/B-tested live 2026-07-21, Emacs libnotify notifications
   ;; (both sync `call-process' AND async `start-process') visibly lagged the
   ;; game, while a direct shell notify-send and the in-process D-Bus path did
   ;; not.  Emacs is the WM, so the spawn's cost (forking a ~2GB/4.4GB-VmSize
   ;; process plus notify-send's own D-Bus round-trip) lands on the WM's main
   ;; thread; the exact split was not pinned, but avoiding the subprocess
   ;; ENTIRELY is what removed the lag.  The `notifications' style sends over
   ;; Emacs's existing D-Bus session connection in-process (no fork, no
   ;; notify-send) and tested smooth.  `alert-fade-time' is inert under this
   ;; style (it sends :timeout -1, so dunst's own per-urgency timeout applies).
   ;; See `.eca/docs/gotchas.md'.
   alert-default-style 'notifications))

;; TODO: make this on save hook for dunstrc
(defun ck/kill-dunst ()
  (interactive)
  (shell-command "pgrep dunst | xargs kill"))

;;; Notification mute: pause dunst for a while, then auto-unmute.  Uses
;;; dunstctl's first-class pause (queued notifications survive and replay on
;;; unmute), not a daemon kill.  Bound to the `s-n' EXWM chord in core/desktop.

(defvar ck/dunst-mute-seconds 3600
  "Default duration, in seconds, that `ck/dunst-mute' silences dunst.")

(defvar ck/dunst--unmute-timer nil
  "Pending timer that re-enables dunst, or nil when notifications are live.")

(defun ck/dunst-paused-p ()
  "Return non-nil when dunst notifications are currently paused."
  (equal "true" (string-trim (shell-command-to-string "dunstctl is-paused"))))

(defun ck/dunst-unmute ()
  "Resume dunst notifications now and cancel any pending auto-unmute."
  (interactive)
  (when (timerp ck/dunst--unmute-timer)
    (cancel-timer ck/dunst--unmute-timer))
  (setq ck/dunst--unmute-timer nil)
  (call-process "dunstctl" nil nil nil "set-paused" "false")
  (message "dunst: notifications on"))

(defun ck/dunst-mute (&optional seconds)
  "Pause dunst for SECONDS, then auto-unmute.
SECONDS defaults to `ck/dunst-mute-seconds'.  With a prefix argument,
prompt for a duration in minutes."
  (interactive
   (list (if current-prefix-arg
             (* 60 (read-number "Mute notifications for (minutes): "
                                (/ ck/dunst-mute-seconds 60)))
           ck/dunst-mute-seconds)))
  (let ((seconds (or seconds ck/dunst-mute-seconds)))
    (when (timerp ck/dunst--unmute-timer)
      (cancel-timer ck/dunst--unmute-timer))
    (call-process "dunstctl" nil nil nil "set-paused" "true")
    (setq ck/dunst--unmute-timer
          (run-at-time seconds nil #'ck/dunst-unmute))
    (message "dunst: muted for %d min" (round (/ seconds 60.0)))))

(defun ck/dunst-toggle-mute ()
  "Toggle dunst mute.  Muting silences for `ck/dunst-mute-seconds' then
auto-unmutes; toggling again while muted unmutes immediately."
  (interactive)
  (if (ck/dunst-paused-p)
      (ck/dunst-unmute)
    (ck/dunst-mute)))

(provide 'config/services/notifications)

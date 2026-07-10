;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'config/desktop/commands)

(use-package alert
  :config
  (setq
   alert-fade-time     180
   alert-default-style 'libnotify))

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

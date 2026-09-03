;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'core/env)
(require 'lib/shell)   ; ck/-run-shell-command

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Brightness

(defun ck/set-brightness (brightness)
  (shell-command
   (concat "sh ~/.scripts/set-brightness.sh " (number-to-string brightness))))

(defun ck/set-high-brightness ()
  (interactive)
  (ck/set-brightness 1))

(defun ck/set-normal-brightness ()
  (interactive)
  (ck/set-brightness 0.9))

(defun ck/set-medium-brightness ()
  (interactive)
  (ck/set-brightness 0.8))

(defun ck/set-low-brightness ()
  (interactive)
  (ck/set-brightness 0.6))

(defun ck/raise-brightness ()
  "raises brightness"
  (interactive)
  (shell-command "sh ~/.scripts/brightness.sh +20"))

(defun ck/lower-brightness ()
  "lowers brightness"
  (interactive)
  (shell-command "sh ~/.scripts/brightness.sh -20"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Audio / volume

(defun ck/espeak (msg)
  (interactive "sText to speak: ")
  (make-process
   :name "espeak"
   :command `("espeak-ng" ,msg)))

(defun ck/cycle-sound ()
  "cycle sound sinks"
  (interactive)
  (shell-command "bash ~/.scripts/cycle-sound.sh"))

;; Volume, mute, and media transport (play/pause, prev, next) are handled
;; outside Emacs by triggerhappy at the evdev layer (nix-conf/modules/
;; media_keys.nix), so the XF86Audio* keys keep working while the screen is
;; locked and transport routes to the active MPRIS player via playerctld.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display / screen

(defun ck/cycle-displays ()
  "cycle displays" ;TODO: pimp out with exwm-randr
  (interactive)
  (shell-command "disper -d eDP-1,DP-3 -r auto --cycle-stages=\"-s:-c:-e\" --cycle -t right"))

(defcustom ck/pg32ucdp-retrain-delay 1.0
  "Seconds to hold the PG32UCDP at 120 Hz before restoring 240 Hz.
The DisplayPort link trains during each modeset.  This delay only gives the
monitor time to lock onto the completed 120 Hz mode before the second modeset."
  :type 'number
  :group 'cmacs)

(defvar ck/pg32ucdp--retrain-process nil)
(defvar ck/pg32ucdp--retrain-timer nil)

(defun ck/pg32ucdp--set-refresh (rate on-success)
  "Set DP-0 to 4K at RATE, then call ON-SUCCESS."
  (let ((buffer (get-buffer-create "*pg32ucdp-retrain*")))
    (with-current-buffer buffer
      (erase-buffer))
    (setq ck/pg32ucdp--retrain-process
          (make-process
           :name "pg32ucdp-retrain"
           :buffer buffer
           :stderr buffer
           :command (list "xrandr" "--output" "DP-0"
                          "--mode" "3840x2160" "--rate" rate)
           :noquery t
           :sentinel
           (lambda (process _event)
             (when (memq (process-status process) '(exit signal))
               (if (zerop (process-exit-status process))
                   (progn
                     (kill-buffer buffer)
                     (funcall on-success))
                 (setq ck/pg32ucdp--retrain-process nil
                       ck/pg32ucdp--retrain-timer nil)
                 (display-buffer buffer)
                 (message "PG32UCDP modeset to %s Hz failed" rate))))))))

(defun ck/pg32ucdp--restore-240hz ()
  "Finish a PG32UCDP retrain by restoring 4K 240 Hz."
  (setq ck/pg32ucdp--retrain-timer nil)
  (ck/pg32ucdp--set-refresh
   "240.02"
   (lambda ()
     (setq ck/pg32ucdp--retrain-process nil)
     (message "PG32UCDP DisplayPort link retrained at 4K 240 Hz"))))

(defun ck/fix-monitor-blackouts ()
  "Recover the PG32UCDP from a black or asleep panel after a monitor wake.
Wake the panel (DPMS on), switch DP-0 to 4K 120 Hz, wait
`ck/pg32ucdp-retrain-delay' seconds, then restore 4K 240 Hz.  The asynchronous
wait does not block the WM Emacs."
  (interactive)
  (when (or (process-live-p ck/pg32ucdp--retrain-process)
            (timerp ck/pg32ucdp--retrain-timer))
    (user-error "A PG32UCDP retrain is already running"))
  ;; Wake the panel first in case DPMS forced it off (the overnight lock chain
  ;; blanks it via `xset dpms force off').  Harmless when it is already awake:
  ;; `force on' is a no-op then.  `+dpms' comes first because the X server
  ;; answers `force on' with BadMatch while DPMS is disabled.  Synchronous, but
  ;; xset returns instantly.
  (call-process "xset" nil nil nil "+dpms")
  (call-process "xset" nil nil nil "dpms" "force" "on")
  (message "Retraining PG32UCDP DisplayPort link via 4K 120 Hz")
  (ck/pg32ucdp--set-refresh
   "119.88"
   (lambda ()
     (message "PG32UCDP locked at 4K 120 Hz; restoring 240 Hz in %.1fs"
              ck/pg32ucdp-retrain-delay)
     (setq ck/pg32ucdp--retrain-timer
           (run-at-time ck/pg32ucdp-retrain-delay nil
                        #'ck/pg32ucdp--restore-240hz)))))

(defun ck/screenshot-to-file (filename)
  "Saves a screenshot to a file"
  (interactive "sFile Name:")
  (ck/-run-shell-command (concat "nix-shell -p imagemagick --run \"import " filename "\"")))

(defun ck/redshift-blue ()
  "Turns the screen normal"
  (interactive)
  (shell-command "redshift -x"))

(defun ck/redshift-orange ()
  "Turns the screen orange"
  (interactive)
  (shell-command "redshift -PO 2000k -b 0.75"))

(defun ck/redshift-red ()
  "Turns the screen red"
  (interactive)
  (shell-command "redshift -PO 1000k -b 0.5"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Input / notifications / misc

(defun ck/conf-mouse ()
  "configures the mouse"
  (interactive)
  (shell-command "xinput set-button-map 'Kensington Slimblade Trackball' 1 2 3 4 5 0 0 3; xinput --set-prop \"Kensington Slimblade Trackball\" \"libinput Accel Speed\" 1"))

(defun ck/switch-keymap ()
  "switch between QWERTY and Colemak"
  (interactive)
(shell-command "sh ~/.scripts/switch-keymap.sh"))

(defun ck/check-time ()
  "checks the time"
  (interactive)
  (shell-command "sh ~/.scripts/check-time.sh"))

(defun ck/check-battery ()
  "checks the battery"
  (interactive)
  (shell-command "sh ~/.scripts/check-battery.sh"))

(defun ck/pause-notifications ()
  "pause dunst notifications"
  (interactive)
  (shell-command "pkill -SIGUSR1 dunst"))

(defun ck/unpause-notifications ()
  "pause dunst notifications"
  (interactive)
  (shell-command "pkill -SIGUSR2 dunst"))

(defun ck/lock-screen ()
  "Lock the screen through xss-lock (logind lock-session -> i3lock-color).
A manual lock means leaving the machine, so it ends caffeine first: the
locked screen then blanks on the normal schedule instead of staying lit."
  (interactive)
  (when (minibufferp)
    (abort-recursive-edit))
  (when (ck/caffeinated-p)
    (ck/decaffeinate))
  (start-process "lock-session" nil "loginctl" "lock-session"))

(defun ck/search-for-file (filename)
  "Search for file in all dirs"
  (interactive "sFile Name: ")
  (async-shell-command
   (concat "fd -IH --hidden " filename " /")
   (generate-new-buffer-name (concat "*Searching for " filename "*"))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Power / session

(defun ck/restart-display-manager ()
  "Restart the display manager"
  (interactive)
  (run-hooks 'kill-emacs-hook)
  (shell-command "sudo /usr/bin/env systemctl restart display-manager.service"))

(defun ck/reboot ()
  "Reboot the system"
  (interactive)
  (run-hooks 'kill-emacs-hook)
  (shell-command "reboot"))

(defun ck/shutdown ()
  "Shut down the system"
  (interactive)
  (run-hooks 'kill-emacs-hook)
  (shell-command "shutdown now"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Caffeine: stretch the idle lock instead of disabling it

;; The idle chain lives in nix-conf/modules/screen_lock.nix as two user
;; units that conflict with each other: `xidlehook' (lock after 5 min) and
;; `xidlehook-caffeinated' (lock after an hour).  Each unit sets the X
;; screensaver and DPMS fallbacks it expects when it starts, so caffeine is
;; a unit swap and nothing else.  The chain still ends in a lock and a
;; blanked panel, so a forgotten caffeine cannot leave the OLED lit all
;; night, and the state is readable from systemd rather than from an Emacs
;; variable that a restart would lose.

(defconst ck/caffeine--normal-unit "xidlehook"
  "User unit running the normal idle chain.")

(defconst ck/caffeine--caffeinated-unit "xidlehook-caffeinated"
  "User unit running the idle chain with the long lock delay.")

(defun ck/caffeine--start-unit (unit)
  "Start user UNIT synchronously and signal an error on failure.
The conflicting chain unit stops as part of the same transaction."
  (let ((status (call-process "systemctl" nil nil nil "--user" "start" unit)))
    (unless (and (integerp status) (zerop status))
      (error "systemctl --user start %s exited with status %s" unit status))))

(defun ck/caffeinated-p ()
  "Return non-nil while the caffeinated idle chain is the active one."
  (zerop (call-process "systemctl" nil nil nil "--user" "--quiet"
                       "is-active" ck/caffeine--caffeinated-unit)))

(defun ck/caffeinate ()
  "Delay the idle lock to an hour until `ck/decaffeinate' or the next login.
Swap the idle chain to `ck/caffeine--caffeinated-unit'.  Screen blanking
and locking still happen, just later."
  (interactive)
  (when (ck/caffeinated-p)
    (user-error "Already caffeinated; run `ck/decaffeinate' to restore"))
  (ck/caffeine--start-unit ck/caffeine--caffeinated-unit)
  (message "Caffeinated: idle lock delayed to an hour"))

(defun ck/decaffeinate ()
  "Restore the normal idle chain.
Safe to run when not caffeinated: starting an already running unit is a
no-op."
  (interactive)
  (ck/caffeine--start-unit ck/caffeine--normal-unit)
  (message "Decaffeinated: idle lock back to the normal schedule"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Keychain

(defun ck/ssh-keychain ()
  "Adds the ssh key to the keychain"
  (interactive)
  (ck/-run-shell-command
   (concat
    "keychain --eval /home/"
    (user-login-name)
    "/.ssh/id_rsa")))

(defun ck/gpg-keychain ()
  "Adds the gpg key to the keychain"
  (interactive)
  (ck/-run-shell-command
   (concat "keychain --eval " user-gpg-id)))

(provide 'config/desktop/commands/system)

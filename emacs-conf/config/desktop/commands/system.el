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
  "Lock the screen through xss-lock (logind lock-session -> xsecurelock)."
  (interactive)
  (when (minibufferp)
    (abort-recursive-edit))
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
;; Caffeine: keep the machine awake, unlocked, and lit

;; The idle chain (nix-conf/modules/screen_lock.nix) has independent parts:
;; the xidlehook user service (idle lock, then DPMS blank), the X screensaver
;; timeout that xss-lock turns into a fallback lock, DPMS itself, and logind
;; suspend.  `ck/caffeinate' pauses every part; `ck/decaffeinate' restores
;; them.  xidlehook reads the X screensaver idle counter, so the timeout must
;; be non-zero again before xidlehook restarts.

(defconst ck/caffeine--default-screensaver-timeout 600
  "X server default screensaver timeout in seconds.
Used when `ck/decaffeinate' has no saved value or the saved value is zero.")

(defvar ck/caffeine--inhibitor nil
  "The `systemd-inhibit' process holding the sleep and idle lock, or nil.")

(defvar ck/caffeine--screensaver-timeout nil
  "X screensaver timeout in seconds saved by `ck/caffeinate', or nil.")

(defun ck/caffeine--run (program &rest args)
  "Run PROGRAM with ARGS synchronously and signal an error on non-zero exit."
  (let ((status (apply #'call-process program nil nil nil args)))
    (unless (and (integerp status) (zerop status))
      (error "%s %s exited with status %s"
             program (string-join args " ") status))))

(defun ck/caffeine--x-screensaver-timeout ()
  "Return the X screensaver timeout in seconds reported by `xset q'."
  (with-temp-buffer
    (unless (zerop (call-process "xset" nil t nil "q"))
      (error "xset q failed"))
    (goto-char (point-min))
    (unless (re-search-forward "^ *timeout: +\\([0-9]+\\)" nil t)
      (error "Could not read the X screensaver timeout from xset q"))
    (string-to-number (match-string 1))))

(defun ck/caffeinated-p ()
  "Return non-nil while `ck/caffeinate' holds the machine awake."
  (process-live-p ck/caffeine--inhibitor))

(defun ck/caffeinate ()
  "Keep the machine awake, unlocked, and lit until `ck/decaffeinate'.
Stop the xidlehook idle timer, zero the X screensaver timeout so the
xss-lock fallback lock never fires, disable DPMS, and hold a logind sleep
and idle inhibitor."
  (interactive)
  (when (ck/caffeinated-p)
    (user-error "Already caffeinated; run `ck/decaffeinate' to restore"))
  (setq ck/caffeine--screensaver-timeout (ck/caffeine--x-screensaver-timeout))
  (ck/caffeine--run "systemctl" "--user" "stop" "xidlehook")
  (ck/caffeine--run "xset" "s" "off")
  (ck/caffeine--run "xset" "-dpms")
  (setq ck/caffeine--inhibitor
        (make-process
         :name "caffeinate"
         :command '("systemd-inhibit" "--what=sleep:idle" "--who=cmacs"
                    "--why=ck/caffeinate" "sleep" "infinity")
         :noquery t))
  (message "Caffeinated: no idle lock, no screen blank, no suspend"))

(defun ck/decaffeinate ()
  "Undo `ck/caffeinate': restore idle lock, screen blanking, and suspend.
Safe to run when not caffeinated, for example after an Emacs restart left
the X screensaver off; every step is idempotent."
  (interactive)
  (when (ck/caffeinated-p)
    (kill-process ck/caffeine--inhibitor))
  (setq ck/caffeine--inhibitor nil)
  (let ((timeout (or ck/caffeine--screensaver-timeout 0)))
    (when (zerop timeout)
      (setq timeout ck/caffeine--default-screensaver-timeout))
    (ck/caffeine--run "xset" "s" (number-to-string timeout)))
  (setq ck/caffeine--screensaver-timeout nil)
  (ck/caffeine--run "xset" "+dpms")
  (ck/caffeine--run "systemctl" "--user" "start" "xidlehook")
  (message "Decaffeinated: idle lock, screen blank, and suspend restored"))


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

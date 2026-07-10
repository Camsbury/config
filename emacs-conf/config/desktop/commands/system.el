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

(defun ck/caffeinate ()
  "Prevent sleep"
  (interactive)
  (ck/-run-shell-command
   "systemd-inhibit --what=sleep --why='Prevent suspend' sleep infinity"))

(defun ck/decaffeinate ()
  "Prevent sleep"
  (interactive)
  (ck/-run-shell-command
   "pkill -f 'systemd-inhibit.*sleep infinity'"))


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

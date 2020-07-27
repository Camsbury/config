(defun global-exwm-key (key cmd)
  "bind key for use across all exwm buffers"
  (general-define-key :keymaps 'exwm-mode-map key cmd)
  (exwm-input-set-key (kbd key) cmd))

(use-package exwm
  :config
  (global-exwm-key "<XF86MonBrightnessUp>"   #'raise-brightness)
  (global-exwm-key "<XF86MonBrightnessDown>" #'lower-brightness)
  (global-exwm-key "<XF86Display>"           #'lock-screen)
  (global-exwm-key "<XF86AudioRaiseVolume>"  #'raise-volume)
  (global-exwm-key "<XF86AudioLowerVolume>"  #'lower-volume)
  (global-exwm-key "<XF86AudioMute>"         #'toggle-mute)
  (global-exwm-key "<XF86AudioPlay>"         #'spotify-toggle-play)
  (global-exwm-key "<XF86AudioPrev>"         #'spotify-prev)
  (global-exwm-key "<XF86AudioNext>"         #'spotify-next)
  (global-exwm-key "s-k"                     #'evil-window-up)
  (global-exwm-key "s-j"                     #'evil-window-down)
  (global-exwm-key "s-h"                     #'evil-window-left)
  (global-exwm-key "s-l"                     #'evil-window-right)
  (global-exwm-key "s-SPC"                   #'hydra-leader/body)
  (global-exwm-key "s-["                     #'hydra-left-leader/body)
  (global-exwm-key "s-]"                     #'hydra-right-leader/body)
  (global-exwm-key "s-c"                     #'exwm-run-command)
  (global-exwm-key "s-b"                     #'check-battery)
  (global-exwm-key "s-t"                     #'check-time)
  (global-exwm-key "s-L"                     #'lock-screen)
  (global-exwm-key "C-SPC"                   #'switch-keymap)
  (global-exwm-key "M-C-s-R"                 #'reboot)
  (exwm-input-set-simulation-keys
   '(([?\s-Y] . ?\C-C)
     ([?\s-y] . ?\C-c))))

(use-package exwm-config
  :after (exwm)
  :config (exwm-config-default))
(use-package exwm-randr
  :after (exwm))

(defun lock-screen ()
  "Locks the screen"
  (interactive)
  (shell-command "slock"))

(defun check-time ()
  "checks the time"
  (interactive)
  (shell-command "sh ~/.scripts/check-time.sh"))

(defun check-battery ()
  "checks the battery"
  (interactive)
  (shell-command "sh ~/.scripts/check-battery.sh"))

(defun cycle-sound ()
  "cycle sound sinks"
  (interactive)
  (shell-command "bash ~/.scripts/cycle-sound.sh"))

(defun cycle-displays ()
  "cycle displays" ;TODO: pimp out with exwm-randr
  (interactive)
  (shell-command "disper -d eDP-1,DP-3 -r auto --cycle-stages=\"-s:-c:-e\" --cycle -t right"))

(defun switch-keymap ()
  "switch between QWERTY and Colemak"
  (interactive)
(shell-command "sh ~/.scripts/switch-keymap.sh"))

(defun raise-brightness ()
  "raises brightness"
  (interactive)
  (let ((default-directory "/sudo::"))
    (shell-command (concat "sh /home/" (getenv "USER") "/.scripts/brightness.sh +20"))))

(defun lower-brightness ()
  "lowers brightness"
  (interactive)
  (let ((default-directory "/sudo::"))
    (shell-command (concat "sh /home/" (getenv "USER") "/.scripts/brightness.sh -20"))))

(defun raise-volume ()
  "raises volume"
  (interactive)
  (shell-command "pactl set-sink-volume @DEFAULT_SINK@ +1000"))

(defun lower-volume ()
  "lowers volume"
  (interactive)
  (shell-command "pactl set-sink-volume @DEFAULT_SINK@ -1000"))

(defun toggle-mute ()
  "toggles mute"
  (interactive)
  (shell-command "pactl set-sink-mute @DEFAULT_SINK@ toggle"))

(defun spotify-toggle-play ()
  "toggles play/pause in Spotify"
  (interactive)
  (shell-command "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause"))

(defun spotify-prev ()
  "goes to the previous track in spotify"
  (interactive)
  (shell-command "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous"))

(defun spotify-next ()
  "goes to the next track in spotify"
  (interactive)
  (shell-command "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next"))

(defun redshift-blue ()
  "Turns the screen normal"
  (interactive)
  (shell-command "redshift -x"))

(defun redshift-orange ()
  "Turns the screen orange"
  (interactive)
  (shell-command "redshift -PO 2000k"))

(defun redshift-red ()
  "Turns the screen red"
  (interactive)
  (shell-command "redshift -PO 1000k"))

(defun reboot ()
  "Reboot the system"
  (interactive)
  (shell-command "reboot"))

(defun exwm-run-command ()
  "Ivy reads available commands and runs one"
  (interactive)
  (ivy-read "Run command: " (s-lines (shell-command-to-string "print -rC1 -- ${(ko)commands}"))
            :action (lambda (command) (interactive (list (read-shell-command "$ "))) (start-process-shell-command command nil command))))

(provide 'core/window_manager)

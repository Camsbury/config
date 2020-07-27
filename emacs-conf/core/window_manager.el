(use-package exwm
  :config (general-define-key :keymaps 'exwm-mode-map
                              "s-SPC" #'hydra-leader/body
                              "s-["   #'hydra-left-leader/body
                              "s-]"   #'hydra-right-leader/body
                              "s-c"   #'exwm-run-command))
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
  (shell-command "sh ~/.scripts/brightness.sh +2"))

(defun lower-brightness ()
  "lowers brightness"
  (interactive)
  (shell-command "sh ~/.scripts/brightness.sh -2"))

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

(defun exwm-run-command ()
  "Ivy reads available commands and runs one"
  (interactive)
  (ivy-read "Run command: " (s-lines (shell-command-to-string "bash -c \"compgen -c\""))
            :action (lambda (command) (interactive (list (read-shell-command "$ "))) (start-process-shell-command command nil command))))

(general-define-key
 "<XF86MonBrightnessUp>"   #'raise-brightness
 "<XF86MonBrightnessDown>" #'lower-brightness
 "<XF86Display>"           #'lock-screen
 "<XF86AudioRaiseVolume>"  #'raise-volume
 "<XF86AudioLowerVolume>"  #'lower-volume
 "<XF86AudioMute>"         #'toggle-mute
 "<XF86AudioPlay>"         #'spotify-toggle-play
 "<XF86AudioPrev>"         #'spotify-prev
 "<XF86AudioNext>"         #'spotify-next
 "s-b"                     #'check-battery
 "s-c"                     #'exwm-run-command
 "s-t"                     #'check-time
 "s-L"                     #'lock-screen
 "C-SPC"                   #'switch-keymap)

(provide 'core/window_manager)

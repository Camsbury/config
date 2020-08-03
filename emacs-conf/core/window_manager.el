(defun global-exwm-key (key cmd)
  "bind key for use across all exwm buffers"
  (general-define-key :keymaps 'exwm-mode-map key cmd)
  (exwm-input-set-key (kbd key) cmd))

(use-package exwm
  :init
  (setq exwm-workspace-show-all-buffers t)
  (setq exwm-layout-show-all-buffers t))

(use-package exwm-config
  :after (exwm)
  :config
  (add-hook 'exwm-update-class-hook
            (lambda ()
              (exwm-workspace-rename-buffer exwm-class-name)))
  (setq exwm-workspace-number 5
        exwm-workspace-current-index 1
        exwm-input-global-keys
        `(([?\s-r] . exwm-reset)
          ([?\s-w] . exwm-workspace-switch)
          ,@(mapcar (lambda (i)
                      `(,(kbd (format "s-%d" i)) .
                        (lambda ()
                          (interactive)
                          (exwm-workspace-switch-create ,i))))
                    (number-sequence 0 9))))
  (exwm-enable) ; assuming this needs to be done before setters are enabled
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
  (global-exwm-key "M-C-s-R"                 #'restart-display-manager)
  (exwm-input-set-simulation-keys
   '(([?\s-a] . ?\C-a)
     ([?\s-C] . ?\C-C)
     ([?\s-c] . ?\C-c)
     ([?\s-V] . ?\C-V)
     ([?\s-v] . ?\C-v))))
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

(defun nix-channel-update ()
  "Rebuild nixos"
  (interactive)
  (let ((default-directory "/sudo::"))
    (shell-command "nix-channel --update")))

(defun nixos-rebuild-switch ()
  "Rebuild nixos"
  (interactive)
  (let ((default-directory "/sudo::"))
    (shell-command "nixos-rebuild switch")))

(defun restart-display-manager ()
  "Restart the display manager"
  (interactive)
  (let ((default-directory "/sudo::"))
    (shell-command "systemctl restart display-manager.service")))

(defun reboot ()
  "Reboot the system"
  (interactive)
  (shell-command "reboot"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; open apllications

(defun -run-shell-command (command)
  "run a shell command"
  (start-process-shell-command command nil command))

(defun find-or-open-application (command name)
  "Finds or opens the application"
  (let* ((buffers (-map #'buffer-name (buffer-list)))
         (match (-first (lambda (buffer) (s-match name buffer)) buffers)))
    (if match
        (switch-to-buffer match)
      (-run-shell-command command))))

(defun open-brave ()
  "Opens the brave browser"
  (interactive)
  (find-or-open-application "brave" "Brave-browser"))

(defun open-spotify ()
  "Opens Spotify"
  (interactive)
  (find-or-open-application "spotify" "Spotify"))

(defun open-slack ()
  "Opens Slack"
  (interactive)
  (find-or-open-application "slack" "Slack"))

(defun open-telegram ()
  "Opens Telegram"
  (interactive)
  (find-or-open-application "telegram-desktop" "TelegramDesktop"))

(defun open-xterm ()
  "Opens the terminal"
  (interactive)
  (find-or-open-application "xterm" "XTerm"))

(defun open-zoom ()
  "Opens the terminal"
  (interactive)
  (find-or-open-application "zoom-us" "zoom"))

(defun exwm-run-command ()
  "Ivy reads available commands and runs one"
  (interactive)
  (ivy-read "Run command: " (s-lines (shell-command-to-string "print -rC1 -- ${(ko)commands}"))
            :action #'-run-shell-command))

(provide 'core/window_manager)

(use-package alarm-clock)
(use-package deadgrep)

(defun -run-shell-command (command)
  "run a shell command"
  (start-process-shell-command command nil command))

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

(defun screenshot-to-file (filename)
  "Saves a screenshot to a file"
  (interactive "sFile Name:")
  (-run-shell-command (concat "nix-shell -p imagemagick --run \"import " filename "\"")))

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
    (async-shell-command
     "nix-channel --update"
     (generate-new-buffer-name "*Nix Update Channels*"))))

(defun nixos-channel-version ()
  "Get the nixos channel version"
  (interactive)
  (kill-new
   (shell-command-to-string "nix-instantiate --eval -E '(import <nixos> {}).lib.version'")))

(defun nixpkgs-channel-version ()
  "Get the nixpkgs channel version"
  (interactive)
  (kill-new
   (shell-command-to-string "nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version'")))

(defun nixos-rebuild-switch ()
  "Rebuild nixos"
  (interactive)
  (let ((default-directory "/sudo::"))
    (async-shell-command
     "nixos-rebuild switch"
     (generate-new-buffer-name "*NixOS Rebuild Switch*"))))

(defun nix-collect-garbage ()
  "Collect garbage"
  (interactive)
  (async-shell-command
   "nix-collect-garbage -d"
   (generate-new-buffer-name "*Nix Collect Garbage*")))

(defun restart-display-manager ()
  "Restart the display manager"
  (interactive)
  (let ((default-directory "/sudo::"))
    (shell-command "systemctl restart display-manager.service")))

(defun nix-derivation-is-cached? (derivation)
  "Sees if the derivation is cached on the nixos cache"
  (interactive "sDerivation Path: ")
  (shell-command
   (concat
    "nix path-info -r "
    derivation
    " --store https://cache.nixos.org/")))

(defun reboot ()
  "Reboot the system"
  (interactive)
  (recentf-save-list)
  (shell-command "reboot"))

(defun shutdown ()
  "Shut down the system"
  (interactive)
  (recentf-save-list)
  (shell-command "shutdown now"))

(defun ssh-keychain ()
  "Adds the ssh key to the keychain"
  (interactive)
  (-run-shell-command "keychain --eval --agents ssh id_rsa"))

(defun gpg-keychain ()
  "Adds the gpg key to the keychain"
  (interactive)
  (-run-shell-command "keychain --eval --agents gpg D3F6CEF58C6E0F38"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; open applications

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Running Shell Commands in Buffers

(defun run-shell-command-in-background (buff-name command)
  "runs a shell command async in a background buffer"
  (interactive "sBuffer name: \nsCommand: ")
  (async-shell-command
   command
   (generate-new-buffer-name (concat "*" buff-name "*"))))

;; derived from https://gist.github.com/PhilHudson/cf882c673599221d42b2
(defun rafd--shell-escaper (matched-text)
    "Return replacement text for MATCHED-TEXT when shell-escaping.
See `shell-escape'."
    (cond
        ((string= matched-text "'")
            "\\\\'")
        ((string-match "\\(.\\)'" matched-text)
            (concat
                (match-string 1 matched-text)
                "\\\\'"))
        (t matched-text)))

;; derived from https://gist.github.com/PhilHudson/cf882c673599221d42b2
(defun rafd--shell-escape (string)
    "Make STRING safe to pass to a shell command."
    (->> string
      (replace-regexp-in-string "\n" " ")
      (replace-regexp-in-string
       ".?'"
       #'rafd--shell-escaper)))


(defun rafd--build-command (dir nix command)
  (concat
   (when dir
     (concat "cd " dir " && "))
   (if nix
       (concat "nix-shell --run '"
               (rafd--shell-escape command)
               "'"))))

(defun run-async-from-desc ()
  "run a shell command async in a background buffer from a description in the
   form of an plist in the form of:
     :name    - name of the buffer
     :dir     - (optional) path to run command from
     :nix     - (optional) `t` if should run in nix-shell
     :command - content of the shell command to run"
  (interactive)
  (let* ((desc    (call-interactively #'lisp-eval-sexp-at-point))
         (name    (plist-get desc :name))
         (dir     (plist-get desc :dir))
         (nix     (plist-get desc :nix))
         (command (plist-get desc :command)))
    (if (and name command)
        (async-shell-command
         (rafd--build-command dir nix command)
         (generate-new-buffer-name (concat "*" name "*")))
      (message "Pease call `run-async-from-desc` with an plist containing the \
`:name` and `:command` keys."))))

(provide 'config/desktop/commands)

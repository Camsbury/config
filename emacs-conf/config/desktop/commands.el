(require 'core/env)

(use-package alarm-clock
  :init
  (defun alarm-message-espeak (title msg)
    (shell-command (concat "espeak \"" msg "\"")))
  :config
  (setq alarm-clock-play-sound nil)
  (advice-add #'alarm-clock--system-notify :after #'alarm-message-espeak))

(use-package deadgrep)

(defun -run-shell-command (command)
  "run a shell command"
  (start-process-shell-command command nil command))

(defun set-brightness (brightness)
  (shell-command
   (concat "sh ~/.scripts/set-brightness.sh " (number-to-string brightness))))

(defun set-high-brightness ()
  (interactive)
  (set-brightness 1))

(defun set-normal-brightness ()
  (interactive)
  (set-brightness 0.9))

(defun set-medium-brightness ()
  (interactive)
  (set-brightness 0.8))

(defun set-low-brightness ()
  (interactive)
  (set-brightness 0.6))

(defun mtgo ()
  (interactive)
  (-run-shell-command "~/projects/pauleve/docker-mtgo/run-mtgo -- --cpuset-cpus 0-3 panard/mtgo:latest"))

(defun espeak (msg)
  (interactive "sText to speak: ")
  (make-process
   :name "espeak"
   :command `("espeak" ,msg)))

(defun lock-screen ()
  "Locks the screen"
  (interactive)
  (shell-command "slock"))

(defun conf-mouse ()
  "configures the mouse"
  (interactive)
  (shell-command "xinput set-button-map 'Kensington Slimblade Trackball' 1 2 3 4 5 0 0 3; xinput --set-prop \"Kensington Slimblade Trackball\" \"Device Accel Constant Deceleration\" 0.5"))

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
  (shell-command "sh ~/.scripts/brightness.sh +20"))

(defun lower-brightness ()
  "lowers brightness"
  (interactive)
  (shell-command "sh ~/.scripts/brightness.sh -20"))

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
  (shell-command "redshift -PO 2000k -b 0.75"))

(defun redshift-red ()
  "Turns the screen red"
  (interactive)
  (shell-command "redshift -PO 1000k -b 0.5"))

(defun nixos-man ()
  (interactive)
  (man "configuration.nix"))

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

(defun nix-search-update-cache ()
  "Update nix search cache"
  (interactive)
  (async-shell-command
   "nix search -u"
   (generate-new-buffer-name (concat "*Updating Nix Search Cache*"))))

(defun nix-search (pkg)
  "search nixpkgs for pkg"
  (interactive "sPackage: ")
  (async-shell-command
   (concat "nix search " pkg)
   (generate-new-buffer-name (concat "*Searching for package: " pkg "*"))))

(defun nixos-option (option)
  "Determine attributes of an option in current nixos expression"
  (interactive "sOption: ")
  (async-shell-command
   (concat "nixos-option " option)
   (generate-new-buffer-name (concat  "*Describing Option: " option "*"))))

(defun ergodox-build-and-flash ()
  "Rebuild ergodox"
  (interactive)
  (let ((default-directory "/sudo::"))
    (async-shell-command
     (concat
      "nix-shell /home/"
      (user-login-name)
      "/projects/Camsbury/config/camerak/shell.nix --run exit")
     (generate-new-buffer-name "*Build and Flash Ergodox*"))))

(defun nix-collect-garbage ()
  "Collect garbage"
  (interactive)
  (async-shell-command
   "nix-collect-garbage -d"
   (generate-new-buffer-name "*Nix Collect Garbage*")))

(defun restart-display-manager ()
  "Restart the display manager"
  (interactive)
  ;; (run-hooks 'kill-emacs-hook)
  (shell-command "sudo /usr/bin/env systemctl restart display-manager.service"))

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
  (run-hooks 'kill-emacs-hook)
  (shell-command "reboot"))

(defun shutdown ()
  "Shut down the system"
  (interactive)
  (run-hooks 'kill-emacs-hook)
  (shell-command "shutdown now"))

(defun ssh-keychain ()
  "Adds the ssh key to the keychain"
  (interactive)
  (-run-shell-command "keychain --eval --agents ssh id_rsa"))

(defun gpg-keychain ()
  "Adds the gpg key to the keychain"
  (interactive)
  (-run-shell-command
   (concat "keychain --eval --agents gpg " user-gpg-id)))


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

(defun open-steam ()
  "Opens Steam"
  (interactive)
  (find-or-open-application "steam" "Steam"))

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

(defun open-all-applications ()
  (interactive)
  (open-brave)
  (open-xterm)
  (open-slack)
  (open-telegram)
  (open-spotify))

(defun align-all-applications ()
  (interactive)
  (dolist (i '((2 "Brave-browser")
               (4 "XTerm")
               (8 "Slack")
               (9 "TelegramDesktop")
               (0 "Spotify")))
    (exwm-workspace-switch (car i))
    (exwm-workspace-switch-to-buffer (cadr i)))
  (exwm-workspace-switch 1))

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

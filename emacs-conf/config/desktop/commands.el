(require 'core/env)
(require 'projectile)
(require 'exwm)

(use-package alarm-clock
  :init
  (defun alarm-message-espeak (title msg)
    (shell-command (concat "espeak \"" msg "\"")))
  :config
  (setq alarm-clock-play-sound nil)
  (setq alarm-clock-system-notify nil)
  (advice-add #'alarm-clock--notify :after #'alarm-message-espeak))

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
  (shell-command "xinput set-button-map 'Kensington Slimblade Trackball' 1 2 3 4 5 0 0 3; xinput --set-prop \"Kensington Slimblade Trackball\" \"libinput Accel Speed\" 1"))

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

(defun pause-notifications ()
  "pause dunst notifications"
  (interactive)
  (shell-command "pkill -SIGUSR1 dunst"))

(defun unpause-notifications ()
  "pause dunst notifications"
  (interactive)
  (shell-command "pkill -SIGUSR2 dunst"))

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
   ;; (shell-command-to-string "nix-instantiate --eval -E '(import <nixos> {}).lib.version'")
   (shell-command-to-string "cat /nix/var/nix/profiles/per-user/root/channels/nixos/svn-revision")))

(defun nixpkgs-channel-version ()
  "Get the nixpkgs channel version"
  (interactive)
  (kill-new
   ;; (shell-command-to-string "nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version'")
   (shell-command-to-string "cat /nix/var/nix/profiles/per-user/root/channels/nixpkgs/svn-revision")))

(defun nixos-rebuild-switch ()
  "Rebuild nixos"
  (interactive)
  (let ((default-directory "/sudo::"))
    (async-shell-command
     "nixos-rebuild switch"
     (generate-new-buffer-name "*NixOS Rebuild Switch*"))))

(defun nix-search (pkg)
  "search nixpkgs for pkg"
  (interactive "sPackage: ")
  (async-shell-command
   (concat "nix --quiet --log-format raw search nixpkgs "
           pkg
           " --json \\\n | jq -r '\n     to_entries[]\n     | \"\\(.value.pname) (\\(.value.version)) — \\(.value.description)\"'")

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
  (run-hooks 'kill-emacs-hook)
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

(defun caffeinate ()
  "Prevent sleep"
  (interactive)
  (-run-shell-command
   "systemd-inhibit --what=sleep --why='Prevent suspend' sleep infinity"))

(defun decaffeinate ()
  "Prevent sleep"
  (interactive)
  (-run-shell-command
   "pkill -f 'systemd-inhibit.*sleep infinity'"))

(defun ssh-keychain ()
  "Adds the ssh key to the keychain"
  (interactive)
  (-run-shell-command "keychain --eval --agents ssh id_rsa"))

(defun gpg-keychain ()
  "Adds the gpg key to the keychain"
  (interactive)
  (-run-shell-command
   (concat "keychain --eval --agents gpg " user-gpg-id)))

(defun ck/search-for-file (filename)
  "Search for file in all dirs"
  (interactive "sFile Name: ")
  (async-shell-command
   (concat "fd -IH --hidden " filename " /")
   (generate-new-buffer-name (concat "*Searching for " filename "*"))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; open applications

(defun find-or-open-application (command name &optional projectp)
  "Finds or opens the application"
  (let* (
         (buffers (-map #'buffer-name (buffer-list)))
         (match (-first (lambda (buffer) (s-match name buffer)) buffers)))
    (if match
        (switch-to-buffer match)
      (let ((default-directory
             (if projectp
                 (or  (projectile-project-root) "~")
               "~")))
        (-run-shell-command command)))))

(defun open-firefox ()
  "Opens the firefox browser"
  (interactive)
  (find-or-open-application "firefox" "firefox"))

(defun open-lutris ()
  "Opens Lutris"
  (interactive)
  (find-or-open-application "lutris" "Lutris"))

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

(defun open-gather ()
  "Opens Gather"
  (interactive)
  (find-or-open-application "gather" "gather"))

(defun open-thunderbird ()
  "Opens Telegram"
  (interactive)
  (find-or-open-application "thunderbird" "thunderbird"))

(defun open-xterm ()
  "Opens the terminal"
  (interactive)
  (let* ((p-name (when (stringp (projectile-project-root))
                   (car (last (f-split (projectile-project-root))))))
         (xterm-name (concat "XTerm - " p-name)))
    (if (stringp p-name)
        (progn
          (find-or-open-application
           (concat "xterm -e 'tmux new -A -s " p-name "'")
           xterm-name
           t)
          (sleep-for 0.3)
          (when (-first (lambda (buffer) (s-match "XTerm$" buffer)) (-map #'buffer-name (buffer-list)))
            (with-current-buffer "XTerm"
              (exwm-workspace-rename-buffer xterm-name))
            ;; FIXME: switching to the buffers old window - maybe remove the exwm-workspace prefix here, but then the cursor isn't in the terminal
            (exwm-workspace-switch-to-buffer xterm-name)))
      (open-global-xterm))))

(defun open-custom-xterm (term-name)
  "Opens the terminal with a custom tmux session"
  (interactive "sTerminal name: ")
  (let* ((xterm-name (concat "XTerm - " term-name)))
    (if (stringp term-name)
        (progn
          (find-or-open-application
           (concat "xterm -e 'tmux new -A -s " term-name "'")
           xterm-name
           t)
          (sleep-for 0.3)
          (when (-first (lambda (buffer) (s-match "XTerm$" buffer)) (-map #'buffer-name (buffer-list)))
            (with-current-buffer "XTerm"
              (exwm-workspace-rename-buffer xterm-name))
            ;; FIXME: switching to the buffers old window - maybe remove the exwm-workspace prefix here, but then the cursor isn't in the terminal
            (exwm-workspace-switch-to-buffer xterm-name)))
      (open-global-xterm))))

(defun open-global-xterm ()
  "Opens the terminal"
  (interactive)
  (find-or-open-application "xterm -e 'tmux new -A -s global'" "XTerm - global")
  (sleep-for 0.3)
  (when (-first (lambda (buffer) (s-match "XTerm$" buffer)) (-map #'buffer-name (buffer-list)))
    (with-current-buffer "XTerm"
      (exwm-workspace-rename-buffer "XTerm - global"))
    (exwm-workspace-switch-to-buffer "XTerm - global")))

(defun open-zoom ()
  "Opens the terminal"
  (interactive)
  (find-or-open-application "zoom-us" "zoom"))

(defun open-all-applications ()
  (interactive)
  (open-firefox)
  (open-xterm)
  (open-slack)
  (open-telegram)
  (open-spotify))

(defun align-all-applications ()
  (interactive)
  (dolist (i '((2 "firefox")
               (4 "XTerm")
               (8 "Slack")
               (9 "TelegramDesktop")
               (0 "Spotify")))
    (exwm-workspace-switch (car i))
    (exwm-workspace-switch-to-buffer (cadr i)))
  (exwm-workspace-switch 1))

(defun exwm-run-command ()
  "Pick a command to run from those available"
  (interactive)
  (-run-shell-command
   (completing-read "Run command: " (s-lines (shell-command-to-string "print -rC1 -- ${(ko)commands}")))))


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

;; -*- lexical-binding: t; -*-
(require 'core/env)
(require 'projectile)
(require 'exwm)

(use-package alarm-clock
  :init
  (defun alarm-message-espeak (title msg)
    (shell-command (concat "espeak-ng \"" msg "\"")))
  :config
  (setq alarm-clock-play-sound nil)
  (setq alarm-clock-system-notify nil)
  (advice-add #'alarm-clock--notify :after #'alarm-message-espeak))

(use-package deadgrep)

(defun ck/-run-shell-command (command)
  "run a shell command"
  (start-process-shell-command command nil command))

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

(defun ck/mtgo ()
  (interactive)
  (ck/-run-shell-command "~/projects/pauleve/docker-mtgo/run-mtgo -- --cpuset-cpus 0-3 panard/mtgo:latest"))

(defun ck/espeak (msg)
  (interactive "sText to speak: ")
  (make-process
   :name "espeak"
   :command `("espeak-ng" ,msg)))

(defun ck/lock-screen ()
  "Locks the screen"
  (interactive)
  (when (minibufferp)
    (abort-recursive-edit))
  (start-process "slock" nil "slock"))

(defun ck/conf-mouse ()
  "configures the mouse"
  (interactive)
  (shell-command "xinput set-button-map 'Kensington Slimblade Trackball' 1 2 3 4 5 0 0 3; xinput --set-prop \"Kensington Slimblade Trackball\" \"libinput Accel Speed\" 1"))

(defun ck/check-time ()
  "checks the time"
  (interactive)
  (shell-command "sh ~/.scripts/check-time.sh"))

(defun ck/check-battery ()
  "checks the battery"
  (interactive)
  (shell-command "sh ~/.scripts/check-battery.sh"))

(defun ck/cycle-sound ()
  "cycle sound sinks"
  (interactive)
  (shell-command "bash ~/.scripts/cycle-sound.sh"))

(defun ck/cycle-displays ()
  "cycle displays" ;TODO: pimp out with exwm-randr
  (interactive)
  (shell-command "disper -d eDP-1,DP-3 -r auto --cycle-stages=\"-s:-c:-e\" --cycle -t right"))

(defun ck/switch-keymap ()
  "switch between QWERTY and Colemak"
  (interactive)
(shell-command "sh ~/.scripts/switch-keymap.sh"))

(defun ck/raise-brightness ()
  "raises brightness"
  (interactive)
  (shell-command "sh ~/.scripts/brightness.sh +20"))

(defun ck/lower-brightness ()
  "lowers brightness"
  (interactive)
  (shell-command "sh ~/.scripts/brightness.sh -20"))

(defun ck/raise-volume ()
  "raises volume"
  (interactive)
  (shell-command "wpctl set-volume @DEFAULT_SINK@ 5%+"))

(defun ck/lower-volume ()
  "lowers volume"
  (interactive)
  (shell-command "wpctl set-volume @DEFAULT_SINK@ 5%-"))

(defun ck/pause-notifications ()
  "pause dunst notifications"
  (interactive)
  (shell-command "pkill -SIGUSR1 dunst"))

(defun ck/unpause-notifications ()
  "pause dunst notifications"
  (interactive)
  (shell-command "pkill -SIGUSR2 dunst"))

(defun ck/toggle-mute ()
  "toggles mute"
  (interactive)
  (shell-command "wpctl set-mute @DEFAULT_SINK@ toggle"))

(defun ck/spotify-toggle-play ()
  "toggles play/pause in Spotify"
  (interactive)
  (shell-command "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause"))

(defun ck/spotify-prev ()
  "goes to the previous track in spotify"
  (interactive)
  (shell-command "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous"))

(defun ck/spotify-next ()
  "goes to the next track in spotify"
  (interactive)
  (shell-command "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next"))

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

(defun ck/nixos-man ()
  (interactive)
  (man "configuration.nix"))

(defun ck/nix-channel-update ()
  "Rebuild nixos"
  (interactive)
  (let ((default-directory "/sudo::"))
    (async-shell-command
     "nix-channel --update"
     (generate-new-buffer-name "*Nix Update Channels*"))))

(defun ck/nixos-channel-version ()
  "Get the nixos channel version"
  (interactive)
  (kill-new
   ;; (shell-command-to-string "nix-instantiate --eval -E '(import <nixos> {}).lib.version'")
   (shell-command-to-string "cat /nix/var/nix/profiles/per-user/root/channels/nixos/svn-revision")))

(defun ck/nixpkgs-channel-version ()
  "Get the nixpkgs channel version"
  (interactive)
  (kill-new
   ;; (shell-command-to-string "nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version'")
   (shell-command-to-string "cat /nix/var/nix/profiles/per-user/root/channels/nixpkgs/svn-revision")))

(defun ck/nixos-rebuild-switch ()
  "Rebuild nixos"
  (interactive)
  (let ((default-directory "/sudo::"))
    (async-shell-command
     "nixos-rebuild switch"
     (generate-new-buffer-name "*NixOS Rebuild Switch*"))))

(defun ck/nix-search (pkg)
  "search nixpkgs for pkg"
  (interactive "sPackage: ")
  (async-shell-command
   (concat "nix --quiet --log-format raw search nixpkgs "
           pkg
           " --json \\\n | jq -r '\n     to_entries[]\n     | \"\\(.value.pname) (\\(.value.version)) - \\(.value.description)\"'")

   (generate-new-buffer-name (concat "*Searching for package: " pkg "*"))))

(defun ck/nixos-option (option)
  "Determine attributes of an option in current nixos expression"
  (interactive "sOption: ")
  (async-shell-command
   (concat "nixos-option " option)
   (generate-new-buffer-name (concat  "*Describing Option: " option "*"))))

(defun ck/ergodox-build-and-flash ()
  "Rebuild ergodox"
  (interactive)
  (let ((default-directory "/sudo::"))
    (async-shell-command
     (concat
      "nix-shell /home/"
      (user-login-name)
      "/projects/Camsbury/config/camerak/shell.nix --run exit")
     (generate-new-buffer-name "*Build and Flash Ergodox*"))))

(defun ck/nix-collect-garbage ()
  "Collect garbage"
  (interactive)
  (async-shell-command
   "nix-collect-garbage -d"
   (generate-new-buffer-name "*Nix Collect Garbage*")))

(defun ck/restart-display-manager ()
  "Restart the display manager"
  (interactive)
  (run-hooks 'kill-emacs-hook)
  (shell-command "sudo /usr/bin/env systemctl restart display-manager.service"))

(defun ck/nix-derivation-is-cached? (derivation)
  "Sees if the derivation is cached on the nixos cache"
  (interactive "sDerivation Path: ")
  (shell-command
   (concat
    "nix path-info -r "
    derivation
    " --store https://cache.nixos.org/")))

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

(defun ck/search-for-file (filename)
  "Search for file in all dirs"
  (interactive "sFile Name: ")
  (async-shell-command
   (concat "fd -IH --hidden " filename " /")
   (generate-new-buffer-name (concat "*Searching for " filename "*"))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; open applications

(defun ck/find-or-open-application (command name &optional projectp)
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
        (ck/-run-shell-command command)))))

(defun ck/open-firefox ()
  "Opens the firefox browser"
  (interactive)
  (ck/find-or-open-application "firefox" "firefox"))

(defun ck/open-lutris ()
  "Opens Lutris"
  (interactive)
  (ck/find-or-open-application "lutris" "Lutris"))

(defun ck/open-spotify ()
  "Opens Spotify"
  (interactive)
  (ck/find-or-open-application "spotify" "Spotify"))

(defun ck/open-slack ()
  "Opens Slack"
  (interactive)
  (ck/find-or-open-application "slack" "Slack"))

(defun ck/open-steam ()
  "Opens Steam"
  (interactive)
  (ck/find-or-open-application "steam" "Steam"))

(defun ck/open-telegram ()
  "Opens Telegram"
  (interactive)
  (ck/find-or-open-application "Telegram" "TelegramDesktop"))

(defun ck/open-thunderbird ()
  "Opens Telegram"
  (interactive)
  (ck/find-or-open-application "thunderbird" "thunderbird"))

(defun ck/open-xterm ()
  "Opens the terminal"
  (interactive)
  (let* ((p-name (when (stringp (projectile-project-root))
                   (car (last (f-split (projectile-project-root))))))
         (xterm-name (concat "XTerm - " p-name)))
    (if (stringp p-name)
        (progn
          (ck/find-or-open-application
           (concat "xterm -e 'tmux new -A -s " p-name "'")
           xterm-name
           t)
          (sleep-for 0.3)
          (when (-first (lambda (buffer) (s-match "XTerm$" buffer)) (-map #'buffer-name (buffer-list)))
            (with-current-buffer "XTerm"
              (exwm-workspace-rename-buffer xterm-name))
            ;; FIXME: switching to the buffers old window - maybe remove the exwm-workspace prefix here, but then the cursor isn't in the terminal
            (exwm-workspace-switch-to-buffer xterm-name)))
      (ck/open-global-xterm))))

(defun ck/kill-project-xterm ()
  "Kill the xterm associated with the project"
  (interactive)
  (when-let (p-name (when (stringp (projectile-project-root))
                      (car (last (f-split (projectile-project-root))))))
    (shell-command
     (concat "tmux kill-session -t " p-name))))

(defun ck/open-custom-xterm (term-name)
  "Opens the terminal with a custom tmux session"
  (interactive "sTerminal name: ")
  (let* ((xterm-name (concat "XTerm - " term-name)))
    (if (stringp term-name)
        (progn
          (ck/find-or-open-application
           (concat "xterm -e 'tmux new -A -s " term-name "'")
           xterm-name
           t)
          (sleep-for 0.3)
          (when (-first (lambda (buffer) (s-match "XTerm$" buffer)) (-map #'buffer-name (buffer-list)))
            (with-current-buffer "XTerm"
              (exwm-workspace-rename-buffer xterm-name))
            ;; FIXME: switching to the buffers old window - maybe remove the exwm-workspace prefix here, but then the cursor isn't in the terminal
            (exwm-workspace-switch-to-buffer xterm-name)))
      (ck/open-global-xterm))))

(defun ck/open-global-xterm ()
  "Opens the terminal"
  (interactive)
  (ck/find-or-open-application "xterm -e 'tmux new -A -s global'" "XTerm - global")
  (sleep-for 0.3)
  (when (-first (lambda (buffer) (s-match "XTerm$" buffer)) (-map #'buffer-name (buffer-list)))
    (with-current-buffer "XTerm"
      (exwm-workspace-rename-buffer "XTerm - global"))
    (exwm-workspace-switch-to-buffer "XTerm - global")))

(defun ck/open-zoom ()
  "Opens the terminal"
  (interactive)
  (ck/find-or-open-application "zoom-us" "zoom"))

(defun ck/open-all-applications ()
  (interactive)
  (ck/open-firefox)
  (ck/open-xterm)
  (ck/open-slack)
  (ck/open-telegram)
  (ck/open-spotify))

(defun ck/align-all-applications ()
  (interactive)
  (dolist (i '((2 "firefox")
               (4 "XTerm")
               (8 "Slack")
               (9 "TelegramDesktop")
               (0 "Spotify")))
    (exwm-workspace-switch (car i))
    (exwm-workspace-switch-to-buffer (cadr i)))
  (exwm-workspace-switch 1))

(defun ck/exwm-run-command ()
  "Pick a command to run from those available"
  (interactive)
  (ck/-run-shell-command
   (completing-read "Run command: " (s-lines (shell-command-to-string "print -rC1 -- ${(ko)commands}")))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Running Shell Commands in Buffers

(defun ck/run-shell-command-in-background (buff-name command)
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

(defun ck/run-async-from-desc ()
  "run a shell command async in a background buffer from a description in the
   form of an plist in the form of:
     :name    - name of the buffer
     :dir     - (optional) path to run command from
     :nix     - (optional) `t` if should run in nix-shell
     :command - content of the shell command to run"
  (interactive)
  (let* ((desc    (call-interactively #'ck/lisp-eval-sexp-at-point))
         (name    (plist-get desc :name))
         (dir     (plist-get desc :dir))
         (nix     (plist-get desc :nix))
         (command (plist-get desc :command)))
    (if (and name command)
        (async-shell-command
         (rafd--build-command dir nix command)
         (generate-new-buffer-name (concat "*" name "*")))
      (message "Pease call `ck/run-async-from-desc` with an plist containing the \
`:name` and `:command` keys."))))

(provide 'config/desktop/commands)

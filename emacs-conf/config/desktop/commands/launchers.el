;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'projectile)
(require 'exwm)

(defun ck/mtgo ()
  (interactive)
  (ck/-run-shell-command "~/projects/pauleve/docker-mtgo/run-mtgo -- --cpuset-cpus 0-3 panard/mtgo:latest"))


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

(provide 'config/desktop/commands/launchers)

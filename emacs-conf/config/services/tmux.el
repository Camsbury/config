;; -*- lexical-binding: t; -*-
(require 's)
(require 'config/desktop/commands)
(require 'projectile)

(defun ck/tmux-session-pid (session)
  "Fetch a tmux session pid"
  (s-trim
   (shell-command-to-string
    (concat "tmux list-panes -t " session " -F '#{pane_pid}'"))))

(defun ck/tmux-send-stdout (text)
  "Send a string to tmux stderr"
  (interactive "sText: ")
  (let* ((session     (car (last (f-split (projectile-project-root)))))
         (session-pid (ck/tmux-session-pid session)))
    (ck/-run-shell-command
     (concat
      "echo \""
      (s-trim text)
      "\" > /proc/"
      session-pid
      "/fd/1"))))

(defun ck/tmux-send-stderr (text)
  "Send a string to tmux stderr"
  (interactive "sText: ")
  (let* ((session     (car (last (f-split (projectile-project-root)))))
         (session-pid (ck/tmux-session-pid session)))
    (ck/-run-shell-command
     (concat
      "echo \""
      (s-trim text)
      "\" > /proc/"
      session-pid
      "/fd/2"))))

(provide 'config/services/tmux)

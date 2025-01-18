(require 'prelude)
(require 'config/desktop/commands)

(use-package alert
  :config
  (setq
   alert-fade-time     180
   alert-default-style 'libnotify))

;; TODO: make this on save hook for dunstrc
(defun kill-dunst ()
  (interactive)
  (shell-command "pgrep dunst | xargs kill"))

(provide 'config/services/notifications)

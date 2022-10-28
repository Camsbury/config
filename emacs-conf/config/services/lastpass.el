(require 'core/env)

(use-package lastpass
  :config
  ;; was trying to access /bin/bash
  (setq lastpass-shell "bash")
  (setq lastpass-user user-email)
  (setq lastpass-trust-login t)
  (lastpass-auth-source-enable))

(defun lastpass-apps ()
  (-drop-last
   1
   (split-string (shell-command-to-string "lpass ls --format=%an") "\n")))

(defun lastpass-copy-username ()
  (interactive)
  (ivy-read
   "App: "
   (lastpass-apps)
   :action (lambda (x)
             (kill-new
              (s-chomp
               (shell-command-to-string
                (concat  "lpass show --user " x)))))))

(defun lastpass-copy-password ()
  (interactive)
  (ivy-read
   "App: "
   (lastpass-apps)
   :action (lambda (x)
             (kill-new
              (s-chomp
               (shell-command-to-string
                (concat  "lpass show --password " x)))))))



(provide 'config/services/lastpass)


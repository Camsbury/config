
(defun git-init ()
  "initialize git"
  (interactive)
  (shell-command "git init && touch .gitignore"))

(defun lorri-init ()
  "initialize lorri"
  (interactive)
  (shell-command "lorri init && direnv allow"))

(defun lorri-watch ()
  "lorri watcher for nix changes"
  (interactive)
  (async-shell-command "lorri watch"))

(provide 'dev/project)

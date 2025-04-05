(require 'prelude)
(require 'config/search)
(require 'hide-comnt)

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

(defun open-project-shell-nix ()
  "Opens the project's shell.nix"
  (interactive)
  (->>
   "shell.nix"
   (f-join (projectile-project-root))
   (find-file)))

(provide 'config/dev/project)

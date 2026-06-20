;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'config/search)
(require 'hide-comnt)

(defun ck/git-init ()
  "initialize git"
  (interactive)
  (shell-command "git init && touch .gitignore"))

(defun ck/lorri-init ()
  "initialize lorri"
  (interactive)
  (shell-command "lorri init && direnv allow"))

(defun ck/lorri-watch ()
  "lorri watcher for nix changes"
  (interactive)
  (async-shell-command "lorri watch"))

(defun ck/open-project-shell-nix ()
  "Opens the project's shell.nix"
  (interactive)
  (->>
   "shell.nix"
   (f-join (projectile-project-root))
   (find-file)))

(provide 'config/dev/project)

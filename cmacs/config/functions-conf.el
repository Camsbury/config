;; Functions for my emacs config

(require 'dash)

(defun spawn-below ()
  "Spawns a window below"
  (interactive)
  (split-window-below)
  (windmove-down))

(defun spawn-right ()
  "Spawns a window to the right"
  (interactive)
  (split-window-right)
  (windmove-right))

(defun spawn-project-file ()
  "Spawns a project file to the right"
  (interactive)
  (spawn-right)
  (project-find-file))

(defun spawn-recent-file ()
  "Spawns a project file to the right"
  (interactive)
  (spawn-right)
  (counsel-recentf))

(defun spawn-bindings ()
  "Spawns the bindings file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/.emacs.d/config/bindings-conf.el"))

(defun spawn-config ()
  "Spawns the bindings file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/.emacs.d/config/config.el"))

(defun spawn-zshrc ()
  "Spawns the bindings file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/.zshrc"))

(defun spawn-xmonad ()
  "Spawns the XMonad conf file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/.xmonad/xmonad.hs"))

(defun spawn-emacs-nix ()
  "Spawns the bindings file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/projects/nix_dots/emacs.nix"))

(defun spawn-functions ()
  "Spawns the bindings file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/.emacs.d/config/functions-conf.el"))

(defun open-tmp-org ()
  "opens a temporary org file"
  (interactive)
  (evil-window-vsplit)
  (find-file "/tmp/notes.org"))

(provide 'functions-conf)

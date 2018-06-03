;; Bindings for my emacs config

(require 'functions-conf)

(setq x-super-keysym 'meta)
(setq x-meta-keysym 'super)

(general-create-definer my-leader-def
  :prefix "SPC")

(general-create-definer my-mode-leader-def
  :prefix "SPC m")

(general-create-definer my-config-def
  :prefix "SPC SPC c")

(general-define-key
 "s-x" 'execute-extended-command
 "C-h" 'evil-window-left
 "C-j" 'evil-window-down
 "C-k" 'evil-window-up
 "C-l" 'evil-window-right
 "M-q" (if (daemonp) 'delete-frame 'save-buffers-kill-emacs))

(general-def 'normal
  "U" 'undo-tree-visualize
  "]t" 'evil-next-buffer
  "[t" 'evil-prev-buffer
  "]f" 'text-scale-increase
  "[f" 'text-scale-decrease
  "]r" 'undo-tree-restore-state-from-register
  "[r" 'undo-tree-save-state-to-register
  "M-d" 'evil-multiedit-match-symbol-and-next
  "M-d" 'evil-multiedit-match-symbol-and-prev)

(general-def 'motion
  "]e" 'flycheck-next-error
  "[e" 'flycheck-previous-error)

(general-def '(normal visual)
  "gc" 'evil-commentary)

(general-def 'visual
  "S" 'evil-surround-region
  "M-d" 'evil-multiedit-match-and-next
  "M-d" 'evil-multiedit-match-and-prev)

(general-def 'operator
  "s" 'evil-surround-edit)

(my-leader-def 'normal
  "TAB" 'describe-key
  "DEL" 'spawn-project-file
  "RET" 'spawn-recent-file
  ")"   'eval-defun
  "d"   'evil-goto-definition
  "e"   'counsel-projectile-find-file
  "g"   'magit-status
  "G"   'magit-blame
  "h"   'org-capture
  "i"   'imenu
  "j"   'spawn-below
  "k"   'delete-window
  "K"   'kill-this-buffer
  "l"   'spawn-right
  "n"   'counsel-recentf
  "p"   'counsel-projectile-switch-project
  "P"   'projectile-invalidate-cache
  "q"   'evil-save-modified-and-close
  "R"   'restart-emacs
  "t"   'find-file
  "w"   'evil-write
  "z"   'git-timemachine-toggle)

(my-leader-def 'visual
  "S" 'sort-lines)

(my-config-def 'normal
  "b" 'spawn-bindings
  "c" 'spawn-config
  "n" 'spawn-zshrc
  "x" 'spawn-xmonad
  "o" 'spawn-emacs-nix
  "f" 'spawn-functions)

(provide 'bindings-conf)

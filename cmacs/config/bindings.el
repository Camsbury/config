;; Bindings for my emacs config

(require 'functions)

(general-create-definer my-leader-def
  :prefix "SPC")

(general-define-key
 "s-x" 'execute-extended-command
 "C-h" 'evil-window-left
 "C-j" 'evil-window-down
 "C-k" 'evil-window-up
 "C-l" 'evil-window-right)

(general-def 'normal
  "U" 'undo-tree-visualize)

(my-leader-def 'normal
  "TAB" 'describe-key
  ")"   'eval-defun
  "g"   'magit-status
  "G"   'magit-blame
  "i"   'imenu
  "k"   'delete-window
  "K"   'kill-this-buffer
  "l"   'spawn-right
  "n"   'counsel-recentf
  "N"   'project-find-file
  "q"   'evil-save-modified-and-close
  "t"   'find-file
  "w"   'evil-write)

(my-leader-def 'visual
  "S" 'sort-lines)

(provide 'bindings)

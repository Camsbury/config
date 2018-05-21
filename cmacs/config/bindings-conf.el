;; Bindings for my emacs config

(require 'functions-conf)

(general-create-definer my-leader-def
  :prefix "SPC")

(general-define-key
 "s-x" 'execute-extended-command
 "C-h" 'evil-window-left
 "C-j" 'evil-window-down
 "C-k" 'evil-window-up
 "C-l" 'evil-window-right)

(general-def 'normal
  "U" 'undo-tree-visualize
  "]t" 'evil-next-buffer
  "[t" 'evil-prev-buffer
  "]f" 'text-scale-increase
  "[f" 'text-scale-decrease
  "]r" 'undo-tree-restore-state-from-register
  "[r" 'undo-tree-save-state-to-register)

(general-def 'motion
  "]e" 'flycheck-next-error
  "[e" 'flycheck-previous-error)

(general-def '(normal visual)
  "gc" 'evil-commentary)

(general-def 'visual
  "S" 'evil-surround-region)

(general-def 'operator
  "s" 'evil-surround-edit)

(my-leader-def 'normal
  "TAB" 'describe-key
  ")"   'eval-defun
  "e"   'evil-goto-definition
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

(provide 'bindings-conf)

;; Bindings for my emacs config

(require 'functions-conf)
(require 'hydra-conf)

(setq x-super-keysym 'meta)
(setq x-meta-keysym 'super)

(general-evil-setup t)

(general-create-definer my-leader-def
  :prefix "SPC")

(general-create-definer my-mode-leader-def
  :prefix "SPC m")

(general-create-definer my-config-def
  :prefix "SPC c")

(general-define-key
 "s-x" #'counsel-M-x
 "M-x" #'counsel-M-x
 "C-h" #'evil-window-left
 "C-j" #'evil-window-down
 "C-k" #'evil-window-up
 "C-l" #'evil-window-right
 "C-u" #'evil-scroll-up)

(general-def 'normal
  "U"   #'undo-tree-visualize
  "[b"  #'rename-buffer
  "]b"  #'view-buffer
  "]t"  #'evil-next-buffer
  "[t"  #'evil-prev-buffer
  "]f"  #'text-scale-increase
  "[f"  #'text-scale-decrease
  "]r"  #'undo-tree-restore-state-from-register
  "[r"  #'undo-tree-save-state-to-register
  "]n"  #'buf-move-right
  "[n"  #'buf-move-left
  "M-d" #'evil-multiedit-match-symbol-and-next
  "M-D" #'evil-multiedit-match-symbol-and-prev)

(general-def 'motion
  "]e" #'flycheck-next-error
  "[e" #'flycheck-previous-error)

(general-def '(normal visual)
  "gt" #'toggle-test
  "gc" #'evil-commentary)

(general-def 'visual
  "S"   #'evil-surround-region
  "M-d" #'evil-multiedit-match-and-next
  "M-d" #'evil-multiedit-match-and-prev)

(general-def 'operator
  "s" #'evil-surround-edit)

(my-leader-def 'normal
  "TAB" #'describe-key
  "DEL" #'spawn-project-file
  "RET" #'spawn-recent-file
  "["   #'describe-function
  "]"   #'switch-to-buffer
  "("   #'eval-print-last-sexp
  ")"   #'eval-defun
  ;; "a"
  "A"   #'org-agenda-list
  "b"   #'blind-mode
  ;; "B"
  ;; "c" -- the config leader
  ;; "C"
  "d"   #'evil-goto-definition
  ;; "D"
  "e"   #'counsel-projectile-find-file
  ;; "E"
  "f"   #'counsel-rg
  ;; "F"
  "g"   #'magit-status
  "G"   #'magit-blame
  "h"   #'org-capture
  "H"   #'open-tmp-org
  "i"   #'imenu
  ;; "I"
  "j"   #'spawn-below
  ;; "J"
  "k"   #'pretty-delete-window
  "K"   #'kill-this-buffer
  "l"   #'spawn-right
  "L"   #'org-todo-list
  ;; "m" -- the mode leader
  "M"   #'hydra-merge/body
  "n"   #'counsel-recentf
  ;; "N"
  "o"   #'spawn-project-tasks
  ;; "O"
  "p"   #'counsel-projectile-switch-project
  "P"   #'projectile-invalidate-cache
  "q"   #'evil-save-modified-and-close
  "Q"   (if (daemonp) #'delete-frame #'save-buffers-kill-emacs)
  ;; "r"
  "R"   #'restart-emacs
  "s"   #'avy-goto-char
  "S"   #'spawn-se-principles
  "t"   #'counsel-find-file
  ;; "T"
  "u"   #'prettify-windows
  ;; "U"
  ;; "v"
  ;; "V"
  "w"   #'evil-write
  "W"   #'eww-new
  ;; "x"
  ;; "X"
  "y"   #'nav-flash-line
  ;; "Y"
  "z"   #'git-timemachine-toggle
  ;; "Z"
  )

(my-leader-def 'visual
  "S" #'sort-lines)

(my-config-def 'normal
  "b" #'spawn-bindings
  "c" #'spawn-config
  "n" #'spawn-zshrc
  "x" #'spawn-xmonad
  "o" #'spawn-emacs-nix
  "f" #'spawn-functions)

(provide 'bindings-conf)

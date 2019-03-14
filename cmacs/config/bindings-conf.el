;; Bindings for my emacs config

(require 'hydra)
(require 'functions-conf)
(require 'merge-conf)

(setq x-super-keysym 'meta)
(setq x-meta-keysym 'super)

(general-evil-setup t)

;;; allows easy remapping in hydras
(setq hydra-look-for-remap t)

(defhydra hydra-describe (:exit t)
  "describe"
  ("k" #'describe-key      "key")
  ("f" #'describe-function "function")
  ("m" #'describe-mode     "mode")
  ("v" #'describe-variable "variable"))

(defhydra hydra-config (:exit t)
  "spawn config"
  ("b" #'spawn-bindings  "bindings")
  ("c" #'spawn-config    "config")
  ("l" #'spawn-clubhouse "clubhouse")
  ("n" #'spawn-zshrc     "zshrc")
  ("x" #'spawn-xmonad    "xmonad")
  ("o" #'spawn-emacs-nix "emacs.nix")
  ("f" #'spawn-functions "functions"))

(defhydra hydra-spawn (:exit t)
  "spawn"
  ("e" (spawnify #'counsel-projectile-find-file)      "project file")
  ("h" (spawnify #'open-tmp-org)                      "tmp org")
  ("n" (spawnify #'counsel-recentf)                   "recent file")
  ("N" (spawnify #'open-new-tmp)                      "new file")
  ("o" #'spawn-project-tasks                          "project tasks")
  ("p" (spawnify #'counsel-projectile-switch-project) "new project")
  ("s" (spawnify #'open-se-principles)                "SE principles")
  ("t" (spawnify #'counsel-find-file)                 "file in dir")
  ("w" (spawnify #'eww-new)                           "web browser"))

(defhydra hydra-nav (:exit t)
  "nav to"
  ("e" #'counsel-projectile-find-file      "project file")
  ("h" #'open-tmp-org                      "tmp org")
  ("n" #'counsel-recentf                   "recent file")
  ("N" #'open-new-tmp                      "new file")
  ("p" #'counsel-projectile-switch-project "new project")
  ("s" #'open-se-principles                "SE principles")
  ("t" #'counsel-find-file                 "file in dir")
  ("w" #'eww-new                           "web browser"))

(defhydra hydra-leader (:exit t :columns 5 :idle 1.5)
  "leader"
  ("[" #'hydra-describe/body          "describe")
  ("]" #'switch-to-buffer             "switch to buffer")
  (")" #'eval-defun                   "eval outer sexp")
  ;; ("a")
  ("A" #'org-agenda-list              "org agenda list")
  ("b" #'blind-mode                   "blind mode")
  ;; ("B")
  ("c" #'hydra-config/body            "spawn config file")
  ("C" #'toggle-command-logging       "toggle command logging")
  ("d" #'evil-goto-definition         "evil jump to def")
  ;; ("D")
  ;; ("e")
  ("E" #'etymology-of-word-at-point   "etymology of word at point")
  ("f" #'counsel-rg                   "find text in project")
  ;; ("F")
  ("g" #'magit-status                 "magit")
  ("G" #'magit-blame                  "git blame")
  ("h" #'org-capture                  "capture")
  ;; ("H")
  ("i" #'imenu                        "search with imenu")
  ;; ("I")
  ("j" #'spawn-below                  "spawn window below")
  ;; ("J")
  ("k" #'pretty-delete-window         "delete window")
  ("K" #'kill-this-buffer             "kill buffer")
  ("l" #'spawn-right                  "spawn window right")
  ("L" #'org-todo-list                "see org todo list")
  ("m" #'empty-mode-leader            "mode leader")
  ("M" #'hydra-merge/body             "merge")
  ("n" #'hydra-spawn/body             "spawn")
  ;; ("N")
  ("o" #'widen-and-zoom-out           "widen")
  ;; ("O")
  ;; ("p")
  ("P" #'projectile-invalidate-cache  "invalidate project cache")
  ("q" #'evil-save-modified-and-close "write quit")
  ("Q" #'save-buffers-kill-emacs      "leave emacs")
  ;; ("r")
  ("R" #'restart-emacs                "restart emacs")
  ("s" #'avy-goto-char-2              "avy jump to char")
  ;; ("S")
  ("t" #'hydra-nav/body               "nav")
  ;; ("T")
  ("u" #'prettify-windows             "prettify")
  ;; ("U")
  ;; ("v")
  ;; ("V")
  ("w" #'evil-write                   "write file")
  ("W" #'evil-save-as                 "save file as")
  ;; ("x")
  ("X" #'toggle-debug-on-error        "toggle debug on error")
  ("y" #'nav-flash-line               "flash line")
  ;; ("Y")
  ("z" #'git-timemachine-toggle       "git timemachine")
  ;; ("Z")
  )

(defhydra hydra-visual-leader (:exit t)
  "visual leader"
  ("s" #'sort-lines "sort lines")
  ("o" #'narrow-and-zoom-in           "narrow and zoom in"))

(defhydra hydra-left-leader (:exit t)
  "left leader"
  ("b" #'rename-buffer                    "rename buffer")
  ("e" #'flycheck-previous-error          "previous error")
  ("t" #'evil-prev-buffer                 "previous buffer")
  ("f" #'text-scale-decrease              "zoom out")
  ("r" #'undo-tree-save-state-to-register "mark undo tree")
  ("n" #'buf-move-left                    "move window left"))

(defhydra hydra-right-leader (:exit t)
  "right leader"
  ("b" #'view-buffer                           "view buffer")
  ("e" #'flycheck-next-error                   "next error")
  ("t" #'evil-next-buffer                      "next buffer")
  ("f" #'text-scale-increase                   "zoom in")
  ("r" #'undo-tree-restore-state-from-register "goto undo tree mark")
  ("n" #'buf-move-right                        "move window right"))

(general-define-key
 "s-x"     #'counsel-M-x
 "M-x"     #'counsel-M-x
 "C-h"     #'evil-window-left
 "C-j"     #'evil-window-down
 "C-k"     #'evil-window-up
 "C-l"     #'evil-window-right
 "C-u"     #'evil-scroll-up
 "C-S-p"   #'yank)

(general-def 'normal
  "SPC" #'hydra-leader/body
  "K"   #'comment-indent-new-line
  "U"   #'undo-tree-visualize
  "["   #'hydra-left-leader/body
  "]"   #'hydra-right-leader/body
  "M-d" #'evil-multiedit-match-symbol-and-next
  "M-D" #'evil-multiedit-match-symbol-and-prev)

(general-def '(normal visual)
  "gt" #'toggle-test
  "gc" #'evil-commentary)

(general-def 'visual
  "SPC" #'hydra-visual-leader/body
  "S"   #'evil-surround-region
  "M-d" #'evil-multiedit-match-and-next
  "M-D" #'evil-multiedit-match-and-prev)

(general-def 'operator
  "s" #'evil-surround-edit)

(provide 'bindings-conf)

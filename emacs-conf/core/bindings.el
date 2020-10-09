;; Bindings for my emacs config

(use-package general)
(use-package which-key)
(use-package hydra)

(setq x-super-keysym 'meta)
(setq x-meta-keysym 'super)


(general-evil-setup t)
(which-key-mode)
(setq which-key-max-display-columns 5)

;;; allows easy remapping in hydras
(setq hydra-look-for-remap t)

(defhydra hydra-describe (:exit t :columns 5)
  "describe"
  ("k" #'describe-key      "key")
  ("f" #'describe-function "function")
  ("m" #'describe-mode     "mode")
  ("v" #'describe-variable "variable"))

(defhydra hydra-config (:exit t :columns 5)
  "spawn config"
  ("b" #'spawn-bindings  "bindings")
  ("c" #'spawn-config    "config")
  ("f" #'spawn-functions "functions"))

(defhydra hydra-spawn (:exit t :columns 5)
  "spawn"
  ("a" (spawnify #'open-daybook)                        "daybook")
  ("b" (spawnify #'open-books)                          "book notes")
  ("c" (spawnify #'open-brave)                          "brave browser")
  ("d" (spawnify #'open-work)                           "work org")
  ("D" (spawnify #'open-dump)                           "brain dump")
  ("e" (spawnify #'counsel-projectile-find-file)        "project file")
  ("E" (spawnify #'counsel-projectile-switch-to-buffer) "project open buffer")
  ("g" (spawnify #'open-telegram)                       "telegram")
  ("h" (spawnify #'open-queue)                          "queue org")
  ("H" (spawnify #'open-tmp-org)                        "tmp org")
  ("j" (spawnify #'open-journal)                        "journal org")
  ("s-k" (spawnify #'open-habits)                       "habits org")
  ("k" (spawnify #'open-slack)                          "slack")
  ("l" (spawnify #'open-links)                          "links org")
  ("m" (spawnify #'mu4e)                                "email")
  ("n" (spawnify #'counsel-recentf)                     "recent file")
  ("N" (spawnify #'open-new-tmp)                        "new file")
  ("o" (spawnify #'open-project-summary)                "project summary")
  ("p" (spawnify #'counsel-projectile-switch-project)   "new project")
  ("r" (spawnify #'open-runs)                           "runs tracker")
  ("s" (spawnify #'open-spotify)                        "spotify")
  ("S" (spawnify #'open-se-principles)                  "SE principles")
  ("t" (spawnify #'counsel-find-file)                   "file in dir")
  ("w" (spawnify #'eww-new)                             "web browser")
  ("x" (spawnify #'open-xterm)                          "xterm")
  ("z" (spawnify #'open-zoom)                           "zoom"))

(defhydra hydra-nav (:exit t :columns 5)
  "nav to"
  ("a" #'open-daybook                        "daybook")
  ("b" #'open-books                          "book notes")
  ("c" #'open-brave                          "brave browser")
  ("d" #'open-work                           "work org")
  ("D" #'open-dump                           "brain dump")
  ("e" #'counsel-projectile-find-file        "project file")
  ("E" #'counsel-projectile-switch-to-buffer "project open buffer")
  ("g" #'open-telegram                       "telegram")
  ("h" #'open-queue                          "queue org")
  ("H" #'open-tmp-org                        "tmp org")
  ("j" #'open-journal                        "journal org")
  ("s-k" #'open-habits                       "habits org")
  ("k" #'open-slack                          "slack")
  ("l" #'open-links                          "links org")
  ("m" #'mu4e                                "email")
  ("n" #'counsel-recentf                     "recent file")
  ("N" #'open-new-tmp                        "new file")
  ("o" #'open-project-summary                "project summary")
  ("p" #'counsel-projectile-switch-project   "new project")
  ("r" #'open-runs                           "runs tracker")
  ("s" #'open-spotify                        "spotify")
  ("S" #'open-se-principles                  "SE principles")
  ("t" #'counsel-find-file                   "file in dir")
  ("w" #'eww-new                             "web browser")
  ("x" #'open-xterm                          "xterm")
  ("z" #'open-zoom                           "zoom"))

(defhydra hydra-git (:exit t :columns 5)
  "git"
  ("b" #'magit-blame                       "magit blame")
  ("s" #'magit-status                      "magit status")
  ("t" #'git-timemachine-toggle            "git time machine")
  ("l" #'github-clone                      "github clone"))

(defhydra hydra-register (:exit t :columns 5)
  "set register"
  ("p" #'point-to-register                "save point")
  ("w" #'window-configuration-to-register "save window config"))

(defhydra hydra-link (:exit t :columns 5)
  "set register"
  ("q" (xdg-open 'gh-nots)  "github notifications")
  ("w" (xdg-open 'weather)  "weather")
  ("z" (xdg-open 'q-course) "quantopian")
  ("n" (xdg-open 'shows)    "shows"))

(defhydra hydra-leader (:exit t :columns 5 :idle 1.5)
  "leader"
  ("[" #'hydra-describe/body          "describe")
  ("]" #'switch-to-buffer             "switch to buffer")
  (")" #'eval-defun                   "eval outer sexp")
  ;; ("a")
  ("A" #'org-agenda-list              "org agenda list")
  ("b" #'blind-mode                   "blind mode")
  ("B" #'hydra-link/body              "weblinks")
  ("c" #'hydra-config/body            "spawn config file")
  ("C" #'toggle-command-logging       "toggle command logging")
  ("d" #'evil-goto-definition         "evil jump to def")
  ("D" #'dumb-jump-go                 "dumb jump")
  ;; ("e")
  ("E" #'etymology-of-word-at-point   "etymology of word at point")
  ("f" #'counsel-rg                   "find text in project")
  ;; ("F")
  ("g" #'hydra-git/body               "git tasks")
  ;; ("G")
  ("h" #'org-capture                  "capture")
  ;; ("H")
  ("i" #'counsel-imenu                "search with imenu")
  ;; ("I")
  ("j" #'spawn-below                  "spawn window below")
  ;; ("J")
  ("k" #'pretty-delete-window         "delete window")
  ("s-k" (lambda ()
           (interactive)
           (kill-this-buffer)
           (pretty-delete-window))       "kill buffer and delete window")
  ("K" #'kill-this-buffer             "kill buffer")
  ("l" #'spawn-right                  "spawn window right")
  ;; ("L")
  ("m" #'empty-mode-leader            "mode leader")
  ("M" #'hydra-merge/body             "merge")
  ("n" #'hydra-spawn/body             "spawn")
  ;; ("N")
  ("o" #'widen-and-zoom-out           "widen")
  ;; ("O")
  ("p" #'org-todo-list                "see org todo list")
  ("P" #'projectile-invalidate-cache  "invalidate project cache")
  ("q" #'evil-save-modified-and-close "write quit")
  ("Q" #'clean-quit-emacs             "leave emacs")
  ;; ("r")
  ("R" #'restart-emacs                "restart emacs")
  ("s" #'avy-goto-char-2              "avy jump to char")
  ;; ("S")
  ("t" #'hydra-nav/body               "nav")
  ("T" #'explain-pause-top            "emacs top")
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
  ;; ("z")
  ;; ("Z")
  )

(defhydra hydra-visual-leader (:exit t :columns 5)
  "visual leader"
  ("m" #'empty-visual-mode-leader  "visual mode leader")
  ("o" #'narrow-and-zoom-in "narrow and zoom in")
  ("s" #'sort-lines         "sort lines"))

(defhydra hydra-left-leader (:exit t :columns 5)
  "left leader"
  ("b" #'bookmark-set            "create bookmark at point")
  ("e" #'flycheck-previous-error "previous error")
  ("t" #'evil-prev-buffer        "previous buffer")
  ("f" #'text-scale-decrease     "zoom out")
  ("r" #'hydra-register/body     "save point to register")
  ("n" #'buf-move-left           "move window left")
  ("x" #'org-previous-block      "previous org block"))

(defhydra hydra-right-leader (:exit t :columns 5)
  "right leader"
  ("b" #'counsel-bookmark    "open/create bookmark")
  ("e" #'flycheck-next-error "next error")
  ("t" #'evil-next-buffer    "next buffer")
  ("f" #'text-scale-increase "zoom in")
  ("r" #'jump-to-register    "jump to register")
  ("n" #'buf-move-right      "move window right")
  ("x" #'org-next-block      "next org block"))

(general-define-key
 "s-x"        #'counsel-M-x
 "M-n"        #'goto-address-at-point
 "M-x"        #'counsel-M-x
 "C-u"        #'evil-scroll-up
 "C-S-p"      #'yank)

(general-def 'normal
  "SPC" #'hydra-leader/body
  "k"   #'evil-previous-visual-line
  "j"   #'evil-next-visual-line
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

(provide 'core/bindings)

(require 'prelude)

;; swapping alt and windows for meta/super
(setq x-super-keysym 'meta
      x-meta-keysym 'super)

(use-package general
  :config
  (general-evil-setup t))
(use-package which-key
  :config
  (which-key-mode)
  (setq which-key-max-display-columns 5))
(use-package hydra
  :config
  ;;; allows easy remapping in hydras
  (setq hydra-look-for-remap t))

;; nice tooltip for unbound mode hydras
(defun empty-mode-leader ()
  (interactive)
  (message "current mode hydra is unbound"))

(defun empty-visual-mode-leader ()
  (interactive)
  (message "current visual mode hydra is unbound"))

(defhydra hydra-describe (:exit t :columns 5)
  "describe"
  ("k" #'helpful-key      "key")
  ("f" #'counsel-describe-function "function")
  ("m" #'describe-mode     "mode")
  ("v" #'counsel-describe-variable "variable"))

(defhydra hydra-config (:exit t :columns 5)
  "spawn config file"
  ("b" #'spawn-bindings  "bindings"))

;; CLEAN: remove stuff I never use, or shove behind another hydra
(defhydra hydra-spawn (:exit t :columns 5)
  "spawn"
  ("a" (spawnify #'grab-daybook)                        "daybook")
  ("b" (spawn-file-link :books)                         "book notes")
  ("c" (spawnify #'open-brave)                          "brave browser")
  ("D" (spawn-file-link :brain-dump)                    "brain dump")
  ("e" (spawnify #'counsel-projectile-find-file)        "project file")
  ("E" (spawnify #'counsel-projectile-switch-to-buffer) "project open buffer")
  ("f" (spawn-file-link :frustrations)                  "view frustrations")
  ("g" (spawnify #'open-telegram)                       "telegram")
  ("h" (spawn-file-link :queue)                         "queue org")
  ("H" (spawn-file-link :notes)                         "tmp org")
  ("j" (spawn-file-link :journal)                       "journal org")
  ("s-k" (spawn-file-link :habits)                      "habits org")
  ("k" (spawnify #'open-slack)                          "slack")
  ("l" (spawn-file-link :links)                         "links org")
  ("m" (spawnify #'mu4e)                                "email")
  ("n" (spawnify #'counsel-recentf)                     "recent file")
  ("N" (spawnify #'open-new-tmp)                        "new file")
  ("o" (spawnify #'open-project-summary)                "project summary")
  ("p" (spawnify #'projectile-switch-project)           "open project")
  ("q" (spawn-file-link :questions)                     "view questions")
  ("r" (spawn-file-link :runs)                          "runs tracker")
  ("R" (spawn-file-link :raw)                           "raw queue")
  ("s" (spawnify #'open-spotify)                        "spotify")
  ("S" (spawn-file-link :se-principles)                 "SE principles")
  ("t" (spawnify #'counsel-find-file)                   "file in dir")
  ("w" (spawnify #'eww-new)                             "web browser")
  ("x" (spawnify #'open-xterm)                          "xterm")
  ("y" (spawn-file-link :systems)                       "systems")
  ("z" (spawnify #'open-zoom)                           "zoom"))

;; CLEAN: remove stuff I never use, or shove behind another hydra
(defhydra hydra-nav (:exit t :columns 5)
  "nav to"
  ("a" #'grab-daybook                        "daybook")
  ("b" (open-file-link :books)               "book notes")
  ("c" #'open-brave                          "brave browser")
  ("D" (open-file-link :brain-dump)          "brain dump")
  ("e" #'counsel-projectile-find-file        "project file")
  ("E" #'counsel-projectile-switch-to-buffer "project open buffer")
  ("f" (open-file-link :frustrations)        "view frustrations")
  ("g" #'open-telegram                       "telegram")
  ("h" (open-file-link :queue)               "queue org")
  ("H" (open-file-link :notes)               "tmp org")
  ("j" (open-file-link :journal)             "journal org")
  ("s-k" (open-file-link :habits)            "habits org")
  ("k" #'open-slack                          "slack")
  ("m" #'mu4e                                "email")
  ("n" #'counsel-recentf                     "recent file")
  ("N" #'open-new-tmp                        "new file")
  ("o" #'open-project-summary                "project summary")
  ("p" #'projectile-switch-project           "open project")
  ("q" (open-file-link :questions)           "view questions")
  ("r" (open-file-link :runs)                "runs tracker")
  ("R" (open-file-link :raw)                 "raw queue")
  ("s" #'open-spotify                        "spotify")
  ("S" (open-file-link :se-principles)       "SE principles")
  ("t" #'counsel-find-file                   "file in dir")
  ("w" #'eww-new                             "web browser")
  ("x" #'open-xterm                          "xterm")
  ("y" (open-file-link :systems)             "systems")
  ("z" #'open-zoom                           "zoom"))

;; USEIT: need to try these out and ese how they compare to bookmarks
(defhydra hydra-register (:exit t :columns 5)
  "set register"
  ("p" #'point-to-register                "save point")
  ("w" #'window-configuration-to-register "save window config")
  ("q" nil))

;;; TODO: find out how to make this mode aware??
(defhydra hydra-merge ()
  "merge"
  ("a" #'smerge-keep-all "keep all")
  ("u" #'smerge-keep-upper "keep upper")
  ("l" #'smerge-keep-lower "keep lower")
  ("p" #'smerge-prev "previous")
  ("n" #'smerge-next "next")
  ("z" #'evil-scroll-line-to-center "center")
  ("q" nil "quit" :color red))

;; USEIT
(defhydra hydra-radio (:exit t :columns 5)
  "radio"
  ("SPC" #'emms-strong-pause          "pause/play")
  ("h"   (open-playlist :hits)        "open hits playlist")
  ("r"   (open-playlist :rock)        "open rock playlist")
  ("v"   (switch-to-buffer "*Radio*") "view radio playlist")
  ("s"   #'emms-random                "random station/track")
  ("["   #'emms-previous              "previous station/track")
  ("]"   #'emms-next                  "next station/track")
  ("q" nil))

(defhydra hydra-window (:exit nil :columns 5)
  "window manipulation"
  ("h" #'evil-window-decrease-width "decrease width")
  ("l" #'evil-window-increase-width "increase width")
  ("j" #'evil-window-decrease-height "decrease height")
  ("k" #'evil-window-increase-height "increase height")
  ("q" nil))

;; USEIT
(defhydra hydra-nixos (:exit t :columns 5)
  "nixos commands"
  ("g" #'nix-collect-garbage     "clean nix store")
  ("m" #'nixos-man               "open man page for configuration.nix")
  ("o" #'nixos-option            "inspect a configuration.nix option")
  ("O" #'nixos-channel-version   "copy nixos channel version")
  ("p" #'nixpkgs-channel-version "copy nixpkgs channel version")
  ("u" #'nix-channel-update      "update channels")
  ("x" #'nixos-rebuild-switch    "update nixos")
  ("f" #'nix-search              "search nixpkgs")
  ("F" #'nix-search-update-cache "update search cache")
  ("q" nil))

;; USEIT
(defhydra hydra-project (:exit t :columns 5)
  "project commands"
  ("g" #'git-init "initialize git")
  ("l" #'lorri-watch "watch lorri")
  ("L" #'lorri-init "initialize lorri")
  ("q" nil))

;; CLEAN: reorganize and get rid of things you never use
(defhydra hydra-leader (:exit t :columns 5 :idle 1.5)
  "leader"
  ("[" #'hydra-describe/body          "describe")
  ("]" #'switch-to-buffer             "switch to buffer")
  (")" #'eval-defun                   "eval outer sexp")
  ("+" #'increment-number-at-point    "increment number")
  ("M-x" #'counsel-M-x                "M-x")
  ;; ("a")
  ("A" #'org-agenda-list              "org agenda list")
  ("b" #'blind-mode                   "blind mode")
  ("c" #'hydra-config/body            "spawn config file")
  ("C" #'toggle-command-logging       "toggle command logging")
  ("d" #'evil-goto-definition         "evil jump to def")
  ("D" #'dumb-jump-go                 "dumb jump")
  ("e" #'hydra-exwm-browser-link/body "browser links")
  ("E" #'etymology-of-word-at-point   "etymology of word at point")
  ("f" #'counsel-rg                   "find text in project")
  ;; USEIT
  ("F" #'swiper-thing-at-point        "find uses of the thing at point")
  ("g" #'hydra-git/body               "git tasks")
  ;; ("G")
  ("h" #'org-capture                  "capture")
  ;; USEIT
  ("H" #'helpful-at-point             "helpful at point")
  ("i" #'counsel-imenu                "search with imenu")
  ("I" #'join-irc                     "join IRCs")
  ("j" #'spawn-below                  "spawn window below")
  ;; ("J")
  ("k" #'delete-window                "delete window")
  ("s-k" #'kill-buffer-and-window     "kill buffer and delete window")
  ("K" #'kill-this-buffer             "kill buffer")
  ("l" #'spawn-right                  "spawn window right")
  ;; USEIT
  ("L" #'list-buffers                 "list buffers")
  ("m" #'empty-mode-leader            "mode leader")
  ("M" #'hydra-merge/body             "merge")
  ("n" #'hydra-spawn/body             "spawn")
  ("N" #'hydra-nixos/body             "nixos")
  ("o" #'widen-and-zoom-out           "widen")
  ;; ("O")
  ("p" #'org-todo-list                "see org todo list")
  ("P" #'hydra-project/body           "project")
  ("q" #'evil-save-modified-and-close "write quit")
  ("r" #'hydra-radio/body             "radio commands")
  ("s" #'avy-goto-char-2              "avy jump to char")
  ;; USEIT
  ("S" #'string-edit-at-point         "edit string")
  ("t" #'hydra-nav/body               "nav")
  ("T" #'explain-pause-top            "emacs top")
  ("u" #'prettify-windows             "prettify")
  ;; ("U")
  ("v" #'hydra-window/body            "window")
  ;; ("V")
  ("w" #'evil-write                   "write file")
  ("W" #'evil-save-as                 "save file as")
  ;; ("x")
  ("X" #'toggle-debug-on-error        "toggle debug on error")
  ("y" #'nav-flash-line               "flash line")
  ;; USEIT
  ("Y" #'copy-buffer-path             "copy buffer path")
  ;; ("z")
  ("Z" #'projectile-kill-buffers      "kill all project buffers"))

(defhydra hydra-visual-leader (:exit t :columns 5)
  "visual leader"
  ("m" #'empty-visual-mode-leader  "visual mode leader")
  ("o" #'narrow-and-zoom-in "narrow and zoom in")
  ("s" #'sort-lines         "sort lines"))

;; CLEAN: reorganize and get rid of things you never use
(defhydra hydra-left-leader (:exit t :columns 5)
  "left leader"
  ("b" #'bookmark-set-and-save   "create bookmark at point")
  ("e" #'flycheck-previous-error "previous error")
  ("t" #'evil-prev-buffer        "previous buffer")
  ("f" #'text-scale-decrease     "zoom out")
  ("r" #'hydra-register/body     "save point to register")
  ("n" #'buf-move-left           "move window left")
  ("x" #'org-previous-block      "previous org block"))

;; CLEAN: reorganize and get rid of things you never use
(defhydra hydra-right-leader (:exit t :columns 5)
  "right leader"
  ("b" #'counsel-bookmark    "open/create bookmark")
  ("e" #'flycheck-next-error "next error")
  ("t" #'evil-next-buffer    "next buffer")
  ("f" #'text-scale-increase "zoom in")
  ("r" #'jump-to-register    "jump to register")
  ("n" #'buf-move-right      "move window right")
  ("x" #'org-next-block      "next org block"))

;;Unbinds annoying accidental commands
(general-define-key :keymaps 'global-map
 "M-ESC ESC" nil)

(general-define-key
 "M-n"        #'goto-address-at-point
 "M-x"        #'counsel-M-x
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

;; CLEAN: reorganize and get rid of things you never use
(general-def '(normal visual) '(text-mode-map prog-mode-map)
  "C-u" #'evil-scroll-up
  "gt"  #'toggle-test
  "gc"  #'evil-commentary)

(general-def 'visual
  "SPC" #'hydra-visual-leader/body
  "S"   #'evil-surround-region
  "M-d" #'evil-multiedit-match-and-next
  "M-D" #'evil-multiedit-match-and-prev)

(general-def 'operator
  "s" #'evil-surround-edit)

(provide 'core/bindings)

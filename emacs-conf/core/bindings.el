;; -*- lexical-binding: t; -*-
(require 'prelude)
;; general (+ general-evil-setup) and the hydra macro come from here.  The hub
;; configures and USES them below (which-key, hydra hints, the hydras and
;; general-def bindings) but no longer bootstraps them itself: keybinding files
;; require the same foundation so their macros expand without depending on the
;; hub having loaded first.
(require 'core/definers)
;; ck/delete-file-and-buffer, ck/unescape-clipboard-string and
;; ck/shuffle-selection (bound in the leaders below) are cross-cutting library
;; ops; pull them from lib/ on demand.
(require 'lib/utils)

;; swapping alt and windows for meta/super
(setq x-super-keysym 'meta
      x-meta-keysym 'super)

(use-package which-key
  :config
  (which-key-mode)
  (setq which-key-max-display-columns 5))
;; Cursor-anchored posframe positioning, shared by vertico-posframe (the
;; floating minibuffer, see config/search.el) and hydra hints (below).  Anchor
;; the box at the cursor of the window active before the popup, instead of dead
;; centre, clamped to stay fully on screen.  Neither caller passes a
;; `:position' to posframe, but posframe sets `:parent-window' in the poshandler
;; info to that pre-popup window, so read its point, inject it as `:position',
;; and defer to posframe's point poshandler (it clamps X into the frame and
;; flips the box upward when placing it below point would overflow the bottom
;; edge, so screen-edge cases stay fully visible for free).
;;
;; FREEZE the result for the life of the popup.  posframe re-runs the poshandler
;; on every refresh, so recomputing from the live point makes previewing
;; commands (switch-to-buffer, consult-line) bounce the box around as they move
;; point.  Cache the first `(x . y)' and reuse it; each caller clears the cache
;; when its popup closes (minibuffer exit / hydra hide), so the next popup
;; re-anchors at the new cursor.
(defvar ck/posframe--point-anchor nil
  "Frozen `(x . y)' for a cursor-anchored posframe, or nil between popups.")
(defun ck/posframe-poshandler-point (info)
  "Anchor the posframe at the parent window's point, frozen once per popup.
See the comment above for why the position is cached rather than
recomputed on every posframe refresh."
  (or ck/posframe--point-anchor
      (setq ck/posframe--point-anchor
            (let* ((win (plist-get info :parent-window))
                   (pt (and (window-live-p win) (window-point win))))
              (posframe-poshandler-point-bottom-left-corner
               (if (integerp pt)
                   (plist-put (copy-sequence info) :position pt)
                 info))))))
(defun ck/posframe-point-anchor-reset (&rest _)
  "Clear the frozen posframe anchor so the next popup re-anchors at point."
  (setq ck/posframe--point-anchor nil))

(use-package hydra
  :config
  ;;; allows easy remapping in hydras
  (setq hydra-look-for-remap t)
  ;; Render hydra hints as a floating posframe box near the cursor (via the
  ;; shared `ck/posframe-poshandler-point' above), matching vertico-posframe,
  ;; instead of the bottom `lv' hint window.  `vertico-posframe-border' loads
  ;; after this file, so its face is absent here; fall back to its
  ;; package-default grey so the two boxes match.  Clear the frozen anchor when
  ;; the hint hides so the next hydra re-anchors.
  (setq hydra-hint-display-type 'posframe
        hydra-posframe-show-params
        (list :internal-border-width 3
              :internal-border-color
              (if (facep 'vertico-posframe-border)
                  (face-attribute 'vertico-posframe-border :background nil t)
                "#525254")
              :left-fringe 8
              :right-fringe 8
              :poshandler #'ck/posframe-poshandler-point))
  (advice-add 'hydra-posframe-hide :after #'ck/posframe-point-anchor-reset))

;; nice tooltip for unbound mode hydras
(defun ck/empty-mode-leader ()
  (interactive)
  (message "current mode hydra is unbound"))

(defun ck/empty-visual-mode-leader ()
  (interactive)
  (message "current visual mode hydra is unbound"))

;; CLEAN: remove stuff I never use, or shove behind another hydra
(defhydra hydra-spawn (:exit t :columns 5)
  "spawn"
  ("a" (ck/spawnify #'org-roam-dailies-goto-today) "daybook")
  ("b" (ck/spawn-file-link :books)                 "book notes")
  ("c" (ck/spawnify #'ck/open-firefox)              "firefox")
  ("e" (ck/spawnify #'projectile-find-file)        "project file")
  ("E" (ck/spawnify #'projectile-switch-to-buffer) "project open buffer")
  ("g" (ck/spawnify #'ck/open-telegram)             "telegram")
  ("H" (ck/spawn-file-link :notes)                 "tmp org")
  ("J" #'org-journal-open-current-journal-file     "org-journal")
  ("k" (ck/spawnify #'ck/open-slack)               "slack")
  ("l" (ck/spawnify #'ck/open-lutris)              "lutris")
  ;; ("m" (ck/spawnify #'mu4e)                        "email")
  ("m" (ck/spawnify #'ck/open-thunderbird)         "thunderbird")
  ("M" (ck/spawnify #'ck/open-steam)               "steam")
  ("n" (ck/spawnify #'recentf)                     "recent file")
  ("N" (ck/spawnify #'ck/open-new-tmp)             "new file")
  ("O" (ck/spawnify #'ck/open-project-summary)     "project summary")
  ("p" (ck/spawnify #'projectile-switch-project)   "open project")
  ("r" (gtd--visit-roam-node "review")             "review")
  ("s" (ck/spawnify #'ck/open-spotify)             "spotify")
  ("t" (ck/spawnify #'find-file)                   "file in dir")
  ("w" (ck/spawnify #'ck/eww-new)                  "web browser")
  ("x" (ck/spawnify #'ck/open-xterm)               "project xterm")
  ("X" (ck/spawnify #'ck/open-global-xterm)        "global xterm")
  ("z" (ck/spawnify #'ck/open-zoom)                "zoom"))

;; CLEAN: remove stuff I never use, or shove behind another hydra
(defhydra hydra-nav (:exit t :columns 5)
  "nav to"
  ("a" #'org-roam-dailies-goto-today           "daybook")
  ("b" (ck/open-file-link :books)              "book notes")
  ("B" #'list-bookmarks                        "list bookmarks")
  ("c" #'ck/open-firefox                       "firefox")
  ("C" #'ck/open-chess-practice                "chess practice")
  ("e" #'projectile-find-file                  "project file")
  ("E" #'projectile-switch-to-buffer           "project open buffer")
  ("g" #'ck/open-telegram                      "telegram")
  ("j" #'org-journal-new-entry                 "org-journal entry")
  ("J" #'org-journal-open-current-journal-file "org-journal")
  ("k" #'ck/open-slack                         "slack")
  ("l" #'ck/open-lutris                        "lutris")
  ;; ("m" #'mu4e                                  "email")
  ("m" #'ck/open-thunderbird                   "thunderbird")
  ("M" #'ck/open-steam                         "steam")
  ("n" #'recentf                               "recent file")
  ("N" #'ck/open-new-tmp                       "new file")
  ("o" #'org-roam-node-find                    "org-roam node")
  ("O" #'ck/open-project-summary               "project summary")
  ("p" #'projectile-switch-project             "open project")
  ("P" (gtd--visit-roam-node "projects")       "gtd projects")
  ("r" (gtd--visit-roam-node "review")         "review")
  ("s" #'ck/open-spotify                       "spotify")
  ("t" #'find-file                             "file in dir")
  ("T" #'ck/open-custom-xterm                  "custom xterm")
  ("u" #'eca                                   "open eca")
  ("w" #'ck/eww-new                            "web browser")
  ("x" #'ck/open-xterm                         "project xterm")
  ("X" #'ck/open-global-xterm                  "global xterm")
  ("z" #'ck/open-zoom                          "zoom"))

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

(defhydra hydra-window (:exit nil :columns 5)
  "window manipulation"
  ("h" #'evil-window-decrease-width "decrease width")
  ("l" #'evil-window-increase-width "increase width")
  ("j" #'evil-window-decrease-height "decrease height")
  ("k" #'evil-window-increase-height "increase height")
  ("y" (lambda () (interactive)
         (evil-window-set-width 190)) "most width")
  ("H" (lambda () (interactive)
         (evil-window-set-width 150)) "half width")
  ("q" nil))

;; USEIT
(defhydra hydra-nixos (:exit t :columns 5)
  "nixos commands"
  ("g" #'ck/nix-collect-garbage     "clean nix store")
  ("m" #'ck/nixos-man               "open man page for configuration.nix")
  ("o" #'ck/nixos-option            "inspect a configuration.nix option")
  ("O" #'ck/nixos-channel-version   "copy nixos channel version")
  ("p" #'ck/nixpkgs-channel-version "copy nixpkgs channel version")
  ("u" #'ck/nix-channel-update      "update channels")
  ("x" #'ck/nixos-rebuild-switch    "update nixos")
  ("f" #'ck/nix-search              "search nixpkgs")
  ("F" #'nix-search-update-cache    "update search cache")
  ("q" nil))

;; USEIT
(defhydra hydra-project (:exit t :columns 5)
  "project commands"
  ("g" #'ck/git-init               "initialize git")
  ("l" #'ck/lorri-watch            "watch lorri")
  ("L" #'ck/lorri-init             "initialize lorri")
  ("s" #'ck/open-project-shell-nix "shell.nix")
  ("q" nil))

;; CLEAN: reorganize and get rid of things you never use
(defhydra hydra-leader (:exit t :columns 5 :idle 1.5)
  "leader"
  ("[" #'hydra-describe/body          "describe")
  ("]" #'switch-to-buffer             "switch to buffer")
  ("+" #'ck/increment-number-at-point    "increment number")
  ("M-x" #'execute-extended-command   "M-x")
  ("a" #'alarm-clock-set              "set an alarm")
  ("b" #'blind-mode                   "blind mode")
  ("c" #'org-roam-capture             "org roam capture")
  ("C" #'ck/toggle-command-logging       "toggle command logging")
  ("d" #'evil-goto-definition         "evil jump to def")
  ("s-d" #'ck/delete-file-and-buffer     "delete current file")
  ("D" #'dumb-jump-go                 "dumb jump")
  ("e" #'hydra-browser/body           "browser links")
  ("s-e" #'ck/doom-theme-edit         "edit theme edn")
  ("E" #'etymology-of-word-at-point   "etymology of word at point")
  ("f" #'consult-ripgrep              "find text in project")
  ;; USEIT
  ("F" #'ck/search-for-file           "search all dirs for file")
  ("g" #'hydra-git/body               "git tasks")
  ;; ("G")
  ("h" #'org-capture                  "capture")
  ;; USEIT
  ("H" #'helpful-at-point             "helpful at point")
  ("i" #'imenu                        "search with imenu")
  ("I" #'ck/join-irc                     "join IRCs")
  ("j" #'ck/spawn-below                  "spawn window below")
  ;; ("J")
  ("k" #'delete-window                "delete window")
  ("s-k" #'kill-buffer-and-window     "kill buffer and delete window")
  ("K" #'kill-current-buffer             "kill buffer")
  ("l" #'ck/spawn-right                  "spawn window right")
  ;; USEIT
  ("L" #'list-buffers                 "list buffers")
  ("m" #'ck/empty-mode-leader            "mode leader")
  ("M" #'hydra-merge/body             "merge")
  ("n" #'hydra-spawn/body             "spawn")
  ("N" #'hydra-nixos/body             "nixos")
  ("s-o" #'ck/widen-and-zoom-out           "widen")
  ("o" #'hydra-gtd/body               "GTD")
  ("O" #'hide/show-comments-toggle    "toggle hiding comments")
  ("p" #'org-todo-list                "see org todo list")
  ("P" #'hydra-project/body           "project")
  ("q" #'evil-save-modified-and-close "write quit")
  ("r" #'hydra-radio/body             "radio commands")
  ("s" #'hydra-eca-nav/body           "eca nav")
  ;; USEIT
  ("S" #'string-edit-at-point         "edit string")
  ;; USEIT
  ("s-s" #'ck/unescape-clipboard-string  "unescape clipboard string")
  ("t" #'hydra-nav/body               "nav")
  ("s-t" #'ck/cycle-theme                "cycle theme")
  ("T" #'explain-pause-top            "emacs top")
  ("u" #'ck/prettify-windows             "prettify")
  ;; ("U")
  ("v" #'hydra-window/body            "window")
  ;; ("V")
  ("w" #'evil-write                   "write file")
  ("W" #'ck/evil-save-as                 "save file as")
  ;; USEIT
  ("x" #'avy-goto-char-2              "avy jump to char")
  ("X" #'toggle-debug-on-error        "toggle debug on error")
  ;; USEIT
  ("y" #'ck/nav-flash-line               "flash line")
  ;; USEIT
  ("Y" #'ck/copy-buffer-path             "copy buffer path")
  ("z" #'ck/breeze-paste-from-clipboard  "breeze it")
  ("Z" #'projectile-kill-buffers      "kill all project buffers"))

(defhydra hydra-visual-leader (:exit t :columns 5)
  "visual leader"
  ("m" #'ck/empty-visual-mode-leader  "visual mode leader")
  ;; ("o" #'ck/narrow-and-zoom-in "narrow and zoom in")
  ("s" #'sort-lines         "sort lines")
  ("S" #'ck/shuffle-selection  "shuffle selection"))

;; CLEAN: reorganize and get rid of things you never use
(defhydra hydra-left-leader (:exit t :columns 5)
  "left leader"
  ("b" #'ck/bookmark-set-and-save   "create bookmark at point")
  ("e" #'flycheck-previous-error "previous error")
  ("t" #'evil-prev-buffer        "previous buffer")
  ("f" #'text-scale-decrease     "zoom out")
  ("r" #'hydra-register/body     "save point to register")
  ("n" #'buf-move-left           "move window left")
  ("x" #'org-previous-block      "previous org block"))

;; CLEAN: reorganize and get rid of things you never use
(defhydra hydra-right-leader (:exit t :columns 5)
  "right leader"
  ("b" #'consult-bookmark    "open/create bookmark")
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
 "C-S-p"      #'yank)

(general-def 'normal
  "SPC" #'hydra-leader/body
  "k"   #'evil-previous-visual-line
  "j"   #'evil-next-visual-line
  "K"   #'comment-indent-new-line
  "U"   #'undo-tree-visualize
  ;; Fuzzy line jump with live preview (leaves native `/' + n/N intact).
  ;; `s' (evil-substitute) is redundant with `cl'; surround lives on the
  ;; operator-state `s' below, so normal-state `s' is free.  Lowercase searches
  ;; this buffer, uppercase (`S', redundant with `cc') searches all buffers.
  "s"   #'consult-line
  "S"   #'consult-line-multi
  "["   #'hydra-left-leader/body
  "]"   #'hydra-right-leader/body
  "M-d" #'evil-multiedit-match-symbol-and-next
  "M-D" #'evil-multiedit-match-symbol-and-prev)

;; CLEAN: reorganize and get rid of things you never use
(general-def '(normal visual) '(text-mode-map prog-mode-map)
  "C-t" #'ck/toggle-tests
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

;; This is THE dispatch hub: the leader hydras forward-reference ~120 commands
;; defined across the config and invoked only at runtime (cider, org,
;; projectile, feature hydras like hydra-git/body, ...).  Cannot `require' them
;; (would force-load deferred packages and invert core-before-config order), so
;; the "unresolved" class is all noise here.  Suppress only it; keep every
;; other class live.  (This also removes the hub's outbound forward-ref
;; edges from the dependency DAG, dissolving the core/bindings <-> dev/git and
;; core/bindings <-> info cycles.)
;;
;; `docstrings' is suppressed for the same reason as org/keys.el: defhydra
;; writes each head's docstring itself, printing lambda bodies and long head
;; names into "Call the head ..." lines that overflow 80 columns and carry
;; unescaped quotes.  Those strings are generated, not editable text.
;; Local Variables:
;; byte-compile-warnings: (not unresolved docstrings)
;; End:

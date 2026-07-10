;; -*- lexical-binding: t; -*-
(require 'prelude)
;; defhydra + the general-* binding macros come from here, so they expand in
;; byte-compile isolation instead of depending on the core/bindings hub.
(require 'core/definers)
;; org owns these keymaps, bound only at runtime; declare so the general-*
;; forms don't warn.
(declare-vars org-capture-mode-map org-mode-map org-src-mode-map)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; my org bindings

(defhydra hydra-org-table ()
  "org table"
  ("o" #'org-table-align "align table")
  ("c" #'org-table-create "create table")
  ("f" #'org-table-eval-formula "eval formula")
  ("j" #'evil-next-line "next row")
  ("k" #'evil-previous-line "previous row")
  ("l" #'org-table-next-field "next field")
  ("h" #'org-table-previous-field "previous field")
  ("x" #'ck/org-table-clear-and-align "clear field")
  ("i" #'ck/org-table-edit-and-align "edit field")
  ("z" #'org-table-toggle-formula-debugger "formula debugger")
  ("q" nil "quit" :color red))

(general-emacs-define-key org-capture-mode-map
  [remap evil-save-and-close]          #'org-capture-finalize
  [remap evil-save-modified-and-close] #'org-capture-finalize
  [remap evil-quit]                    #'org-capture-kill)

;; FIXME: conflicts below
(general-emacs-define-key org-mode-map
  [remap org-meta-return]   #'org-todo
  [remap org-return-indent] #'evil-window-down
  "M-h"                     #'outline-up-heading
  "M-i"                     #'org-id-get-create
  "M-j"                     #'org-forward-heading-same-level
  "M-k"                     #'org-backward-heading-same-level
  "M-l"                     #'org-next-visible-heading
   ;; NOTE: trying this out instead of shallow to see how annoying it is
  "M-o"                     #'org-cycle
  "M-O"                     #'org-show-subtree)
;;; #-org-forward-element - needed on M-l?
;;; #'org-clock-in
;;; #'org-slurp-forward, etc.
;;; #'org-transpose-forward...
;;; org-cycle

(general-def 'normal org-mode-map
 "]" #'hydra-right-leader/body
 "[" #'hydra-left-leader/body
 [remap ck/empty-mode-leader] #'hydra-org/body
 [remap ck/empty-visual-mode-leader] #'hydra-visual-org/body)

(general-def org-mode-map
  "M-a" #'ck/org-insert-todo-heading
  "M-n" #'org-open-at-point
  "M-r" #'org-metaleft
  "M-s" #'ck/org-insert-heading
  "M-t" #'org-metaright)

(defhydra hydra-org-link (:exit t)
  "org-mode links"
  ("e" #'org-store-link     "store a link")
  ("n" #'ck/org-append-link    "insert a link")
  ("t" #'org-open-at-point  "follow a link"))

(defhydra hydra-org-timer (:exit t)
  "org-mode timers"
  ("a" #'org-clock-goto   "goto timer")
  ("o" #'org-clock-report "timer report")
  ("s" #'org-clock-out    "stop timer")
  ("t" #'org-clock-in     "start timer"))

(defhydra hydra-org (:exit t)
  "org-mode"
 ("RET" #'org-sparse-tree          "sparse tree")
 ("I"   #'ck/org-new-item             "new item")
 ("L"   #'ck/org-append-link          "add link")
 ("O"   #'outline-show-all         "show all")
 ("T"   #'hydra-org-table/body     "org table")
 ("Y"   #'org-roam-dailies-find-next-note "next note")
 ("a"   #'org-archive-subtree      "archive")
 ("d"   #'org-deadline             "deadline")
 ("e"   #'org-edit-special         "edit src")
 ("g"   #'ck/org-add-extant-tags      "add extant tags")
 ("i"   #'org-roam-node-insert     "insert roam node")
 ("l"   #'hydra-org-link/body      "org links")
 ("m"   #'hydra-org-timer/body     "org timer")
 ("n"   #'org-narrow-to-subtree    "narrow")
 ("o"   #'ck/org-sparse-tree-at-point "show all")
 ("r"   #'org-refile               "refile")
 ("t"   #'org-set-tags-command     "set tags")
 ("v"   (lambda ()
          (interactive)
          (org-cycle-set-startup-visibility)) "reset viz")
 ("x"   #'org-latex-preview        "latex preview")
 ("y"   #'org-roam-dailies-find-previous-note "find previous daily note"))

(defhydra hydra-visual-org (:exit t)
  "org-mode"
 ("s" #'org-sort "sort"))

(general-def org-src-mode-map
 [remap ck/empty-mode-leader] #'hydra-org-src/body)

(defhydra hydra-org-src (:exit t)
  "org-src-mode"
  ("q" #'org-edit-src-exit "write and quit")
  ("k" #'org-edit-src-abort "quit without saving"))

(provide 'config/langs/org/keys)

;; Keybinding/hydra hub: forward-refs org commands and the leader hydra bodies,
;; invoked only at runtime (unresolved).  The big hydras (hydra-org,
;; hydra-org-table) also emit hint docstrings wider than 80 that defhydra
;; generates, not source text we can rewrap (docstring).  Suppress both classes;
;; keep every other class live.
;; Local Variables:
;; byte-compile-warnings: (not unresolved docstrings)
;; End:

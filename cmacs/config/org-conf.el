(require 'bindings-conf)
(require 'org-clubhouse)
(require 'ob-async)
(require 'ob-ipython)

(setq org-directory (expand-file-name "~/projects/lxndr/")
      org-capture-templates '(("n" "Place in the Inbox" entry
                               (file+headline "~/projects/lxndr/inbox.org" "Inbox") "* [ ] %i%?"))
      org-agenda-files '("~/projects/lxndr/store.org")
      org-refile-targets '(("~/projects/lxndr/queue.org" :maxlevel . 3)
                           ("~/projects/lxndr/store.org" :level . 1)
                           ("~/projects/lxndr/ref.org" :level . 1))
      org-archive-location (concat "~/projects/lxndr/archive/" (format-time-string "%Y-%m") ".org::")
      org-todo-keywords '((sequence "[ ]" "[x]")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org-babel stuff

(setq org-babel-confirm-evaluate nil)
(org-babel-do-load-languages
 'org-babel-load-languages
 '((sql . t)
   (ipython . t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org-clubhouse stuff

(setq org-clubhouse-team-name "urbint"
      org-clubhouse-state-alist
        '(("SOMEDAY"   . "Some Day")
          ("PROPOSED"  . "Proposed")
          ("SCHEDULED" . "Scheduled")
          ("ACTIVE"    . "In Development")
          ("REVIEW"    . "Review")
          ("DONE"      . "Ready for Testing")
          ("DEPLOYED"  . "Deployed")
          ("ABANDONED" . "Abandoned")))

(general-add-hook 'org-mode-hook (list #'org-clubhouse-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; my org functions

(defun org-table-clear-and-align ()
  "Clear a cell, then align the table."
  (interactive)
  (org-table-blank-field)
  (org-table-align))

(defun org-table-edit-and-align ()
  "Edit a cell, then align the table."
  (interactive)
  (call-interactively 'org-table-edit-field)
  (org-table-align))

(defun org-insert-top-level-heading ()
  "Insert top level heading"
  (interactive)
  (insert "* ")
  (call-interactively #'evil-insert))

(defun org-insert-heading ()
  "Insert top level heading"
  (interactive)
  (call-interactively #'outline-insert-heading)
  (call-interactively #'evil-insert))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; my org bindings

(defhydra hydra-org-table ()
  "org table"
  ("o" #'org-table-align "align table")
  ("c" #'org-table-create "create table")
  ("j" #'evil-next-line "next row")
  ("k" #'evil-previous-line "previous row")
  ("l" #'org-table-next-field "next field")
  ("h" #'org-table-previous-field "previous field")
  ("x" #'org-table-clear-and-align "clear field")
  ("i" #'org-table-edit-and-align "edit field")
  ("q" nil "quit" :color red))

(general-emacs-define-key org-capture-mode-map
  [remap evil-save-and-close]          #'org-capture-finalize
  [remap evil-save-modified-and-close] #'org-capture-finalize
  [remap evil-quit]                    #'org-capture-kill)

(general-emacs-define-key org-mode-map
  [remap evil-ret]          #'org-todo
  [remap org-return-indent] #'evil-window-down
  "M-t"                     #'hydra-org-table/body
  "M-h"                     #'outline-up-heading
  "M-j"                     #'org-forward-heading-same-level
  "M-k"                     #'org-backward-heading-same-level
  "M-l"                     #'org-next-visible-heading)
;;; #-org-forward-element - needed on M-l?
;;; #'org-clock-in
;;; #'org-slurp-forward, etc.
;;; #'org-transpose-forward...

(general-def 'normal org-mode-map
 "]"                       #'hydra-right-leader/body
 "["                       #'hydra-left-leader/body
 [remap empty-mode-leader] #'hydra-org/body)

(general-def org-mode-map
  "M-a"                   #'org-insert-top-level-heading
  "M-r"                   #'org-insert-heading
  [remap org-meta-return] #'comment-indent-new-line)

(defhydra hydra-org (:exit t)
  "org-mode"
 ("RET" #'org-sparse-tree      "sparse tree")
 ("a"   #'org-archive-subtree  "archive")
 ("d"   #'org-deadline         "deadline")
 ("r"   #'org-refile           "refile")
 ("t"   #'org-set-tags-command "set tags")
 ("e"   #'org-edit-special     "edit src"))

(general-def org-src-mode-map
 [remap empty-mode-leader] #'hydra-org-src/body)

(defhydra hydra-org-src (:exit t)
  "org-src-mode"
  ("q" #'org-edit-src-exit "write and quit")
  ("k" #'org-edit-src-abort "quit without saving"))

(general-add-hook 'org-mode-hook
  (list 'org-bullets-mode 'org-indent-mode 'visual-line-mode))

(provide 'org-conf)

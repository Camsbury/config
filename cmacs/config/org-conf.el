(require 'bindings-conf)
(require 'org-clubhouse)

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
  (interactive)
  "Clear a cell, then align the table."
  (org-table-blank-field)
  (org-table-align))

(defun org-table-edit-and-align ()
  (interactive)
  "Edit a cell, then align the table."
  (call-interactively 'org-table-edit-field)
  (org-table-align))

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
 "]m"                      #'org-shiftright
 "[m"                      #'org-shiftleft
 [remap empty-mode-leader] #'hydra-org/body
 )

(defhydra hydra-org (:exit t)
  "org-mode"
 ("RET" #'org-sparse-tree      "sparse tree")
 ("a"   #'org-archive-subtree  "archive")
 ("d"   #'org-deadline         "deadline")
 ("r"   #'org-refile           "refile")
 ("t"   #'org-set-tags-command "set tags"))

(general-add-hook 'org-mode-hook
  (list 'org-bullets-mode 'org-indent-mode 'visual-line-mode))

(provide 'org-conf)

(require 'bindings-conf)
;; (require 'company-sql-conf)
(require 'org-clubhouse)
(require 'ob-async)
(require 'company-postgresql)
;; (require 'ob-ipython)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org capture

(setq org-directory (expand-file-name "~/Dropbox/lxndr/")
      org-capture-templates
        '(("n" "Place in the Inbox"
           entry (file+headline "~/Dropbox/lxndr/inbox.org" "Inbox")
           "* [ ] %i%?"))
      org-agenda-files '("~/Dropbox/lxndr/store.org")
      org-refile-targets '(("~/Dropbox/lxndr/queue.org" :maxlevel . 3)
                           ("~/Dropbox/lxndr/store.org" :level . 1)
                           ("~/Dropbox/lxndr/ref.org" :level . 1))
      org-archive-location (concat "~/Dropbox/lxndr/archive/" (format-time-string "%Y-%m") ".org::")
      org-todo-keywords '((sequence "[ ]" "[x]")))

;; auto save on refily
(advice-add 'org-refile :after
        (lambda (&rest _)
        (org-save-all-org-buffers)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org themeing

(set-face-foreground 'org-level-2 "#28fbae")
(set-face-foreground 'org-level-3 "#2876fb")
(set-face-foreground 'org-level-4 "#fbae28")
(set-face-foreground 'org-level-5 "#ceff52")
(set-face-foreground 'org-level-6 "#8352ff")
(set-face-foreground 'org-level-7 "#ff52ce")
(set-face-foreground 'org-level-8 "#52ff83")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org-babel

(setq org-confirm-babel-evaluate nil)
(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (sql . t)
   (R . t)
   (http . t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org-clubhouse

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

(general-add-hook 'org-mode-hook (list #'org-clubhouse-mode
                                       (lambda () (add-to-list 'company-backends 'company-ob-postgresql))))

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

(defun org-insert-heading ()
  "Insert top level heading"
  (interactive)
  (call-interactively #'evil-open-below)
  (call-interactively #'outline-insert-heading))

(defun org-insert-todo-heading ()
  "Insert top level heading"
  (interactive)
  (call-interactively #'evil-open-below)
  (call-interactively #'outline-insert-heading)
  (call-interactively #'org-todo))

(defun org-cycle-shallow (&optional arg)
  "Toggle org-cycle for only one level"
  (interactive "P")
  (unless (eq this-command 'org-shifttab)
    (save-excursion
      (org-beginning-of-line)
      (let (invisible-p)
        (when (and (org-at-heading-p)
                   (or org-cycle-open-archived-trees
                       (not (member org-archive-tag (org-get-tags))))
                   (or (not arg)
                       (setq invisible-p (outline-invisible-p (line-end-position)))))
          (unless invisible-p
            (setq org-cycle-subtree-status 'subtree))
          (org-cycle-internal-local)
          t)))))

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
  ("x" #'org-table-clear-and-align "clear field")
  ("i" #'org-table-edit-and-align "edit field")
  ("z" #'org-table-toggle-formula-debugger "formula debugger")
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
  "M-l"                     #'org-next-visible-heading
  "M-o"                     #'org-cycle-shallow
  "M-O"                     #'org-show-subtree)
;;; #-org-forward-element - needed on M-l?
;;; #'org-clock-in
;;; #'org-slurp-forward, etc.
;;; #'org-transpose-forward...
;;; org-cycle

(general-def 'normal org-mode-map
 "]" #'hydra-right-leader/body
 "[" #'hydra-left-leader/body
 [remap empty-mode-leader] #'hydra-org/body)

(general-def org-mode-map
  "M-a" #'org-insert-todo-heading
  "M-r" #'org-metaleft
  "M-s" #'org-insert-heading
  "M-t" #'org-metaright)

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

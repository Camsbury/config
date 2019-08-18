(require 'bindings-conf)
;; (require 'company-sql-conf)
(require 'dash)
(require 'org-clubhouse)
(require 'ob-async)
(require 'company-postgresql)
;; (require 'ob-ipython)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org capture

(setq org-directory (expand-file-name "~/Dropbox/lxndr/")
      org-capture-templates
        '(("n" "Enqueue"
           entry (file+headline "~/Dropbox/lxndr/queue.org" "backlog")
           "* [ ] %i%?")
          ("i" "Add Insight"
            entry (file+headline "~/Dropbox/lxndr/queue.org" "insights")
            "* %i%?")
          ("t" "Add to Tasks"
           entry (file+headline "~/Dropbox/lxndr/tasks.org" "backlog")
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
;;; org-babel

;; don't ask for confirmation on org-babel evaluation
(setq org-confirm-babel-evaluate nil)

;; languages to support in org-babel
(setq org-babel-enabled-languages
  '((emacs-lisp . t)
    (elixir . t)
    (shell . t)
    (sql . t)
    (sqlite . t)
    (R . t)
    (http . t)))

;; only enable ipython ob on linux for now
(when (string-equal system-type "gnu/linux")
    (setq org-babel-enabled-languages
          (cons '(ipython . t) org-babel-enabled-languages)))

;; load the languages into org-babel
(org-babel-do-load-languages
 'org-babel-load-languages
 org-babel-enabled-languages)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org styling

;; Don't use subpar references
(setq org-table-use-standard-references nil)
;; Don't have lines get sucked into folds
(setq org-cycle-separator-lines -1)
;; Allow letters for ordered lists
(setq org-list-allow-alphabetical 1)
(setq org-ellipsis " ▾")
(setq org-bullets-bullet-list '("•"))
(defun org-faces-init ()
  "Initialize org faces"
  (set-face-attribute 'org-level-1 nil :height 1.0)
  (-map (lambda (x) (set-face-bold-p x nil))
                 '( org-level-1
                    org-level-2
                    org-level-3
                    org-level-4
                    org-level-5
                    org-level-6
                    org-level-7
                    org-level-8))
 (-map (lambda (pair) (set-face-foreground (car pair) (cdr pair)))
                 (-zip-pair
                   '(org-level-1 org-level-2 org-level-3 org-level-4 org-level-5
                     org-level-6 org-level-7 org-level-8)
                   '( "#ceff52" "#fbae28" "#28fbae" "#ff52ce" "#ceff52"
                      "#fbae28" "#28fbae" "#ff52ce"))) )

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

(general-add-hook
 'org-mode-hook
 (list #'org-clubhouse-mode
       'linum-mode
       (lambda ()
         ;; (add-to-list 'company-backends 'company-ob-postgresql)
         (org-faces-init))))


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

(defun org-sparse-tree-at-point ()
  "Focus in on the current point"
  (interactive)
  (org-overview)
  (org-show-context))

(defun org-new-item ()
  "Add a list item"
  (interactive)
  (call-interactively #'evil-open-below)
  (call-interactively #'org-insert-item))

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
  "M-RET"                   #'org-todo
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
 [remap empty-mode-leader] #'hydra-org/body
 [remap empty-visual-mode-leader] #'hydra-visual-org/body)

(general-def org-mode-map
  "M-a" #'org-insert-todo-heading
  "M-n" #'org-open-at-point
  "M-r" #'org-metaleft
  "M-s" #'org-insert-heading
  "M-t" #'org-metaright)

(defhydra hydra-org-link (:exit t)
  "org-mode links"
  ("e" #'org-store-link     "store a link")
  ("n" #'org-append-link    "insert a link")
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
 ("a"   #'org-archive-subtree      "archive")
 ("d"   #'org-deadline             "deadline")
 ("i"   #'org-new-item             "new item")
 ("l"   #'hydra-org-link/body      "org links")
 ("m"   #'hydra-org-timer/body     "org timer")
 ("o"   #'org-sparse-tree-at-point "show all")
 ("O"   #'outline-show-all         "show all")
 ("r"   #'org-refile               "refile")
 ("t"   #'org-set-tags-command     "set tags")
 ("e"   #'org-edit-special         "edit src"))

(defhydra hydra-visual-org (:exit t)
  "org-mode"
 ("s" #'org-sort "sort"))

(general-def org-src-mode-map
 [remap empty-mode-leader] #'hydra-org-src/body)

(defhydra hydra-org-src (:exit t)
  "org-src-mode"
  ("q" #'org-edit-src-exit "write and quit")
  ("k" #'org-edit-src-abort "quit without saving"))

(general-add-hook 'org-mode-hook
  (list 'org-bullets-mode 'org-indent-mode 'visual-line-mode))

(provide 'org-conf)

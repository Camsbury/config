(require 'prelude)
(require 'hydra)
(require 'core/env)
;; TODO: https://stackoverflow.com/questions/17478260/completely-hide-the-properties-drawer-in-org-mode
(require 'org-id)

;; USEIT
;; (use-package ob-ammonite
;;   :config
;;   (require 'ammonite-term-repl)
;;   (setq ammonite-term-repl-auto-detect-predef-file nil))
(use-package ob-async)
(use-package ob-elixir)
(use-package ob-http)
(use-package org-bullets)
(use-package org-alert)
(use-package org-journal
  :config
  (customize-set-variable 'org-journal-dir "~/Dropbox/lxndr/journal/"))
;; USEIT
(use-package org-ml)
;; USEIT
(use-package org-parser)
;; USEIT
(use-package org-ql)
(require 'config/langs/sql)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org modules

(add-to-list 'org-modules 'org-habit t)
(add-to-list 'org-modules 'org-id t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org alert

(setq alert-default-style 'libnotify)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org todos

(setq org-todo-keywords '((sequence "[ ]" "[x]")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org capture

(setq org-directory cmacs-share-path
      org-refile-use-outline-path t
      org-capture-templates
      `(("n" "Enqueue"
         entry (file+headline ,(concat cmacs-share-path "/raw.org") "raw")
         "* [ ] %i%?")
        ("o" "Add to Observations"
         entry (file+headline ,(concat cmacs-share-path "/observations.org") "observations")
         "* [ ] %i%?")
        ("p" "Add to Open-ended Problems"
         entry (file+headline ,(concat cmacs-share-path "/oe-problems.org") "problems")
         "* [ ] %i%?")
        ("f" "Add to Frustrations"
         entry (file+headline ,(concat cmacs-share-path "/frustrations.org") "frustrations")
         "* [ ] %i%?")
        ("h" "Add to Questions"
         entry (file+headline ,(concat cmacs-share-path "/questions.org") "questions")
         "* [ ] %i%?")
        ;; USEIT
        ("l" "Log action"
         entry (file+headline ,(concat cmacs-share-path "/daybook.org") "log")
         "* %i%?"))
      org-agenda-files `(,(concat cmacs-share-path "/daybook.org")
                         ,(concat cmacs-share-path "/store.org")
                         ,(concat cmacs-share-path "/habit-list.org"))
      org-refile-targets `((,(concat cmacs-share-path "/daybook-log.org") :maxlevel . 3)
                           (,(concat cmacs-share-path "/daybook.org") :maxlevel . 3)
                           (,(concat cmacs-share-path "/queue.org") :maxlevel . 3)
                           (,(concat cmacs-share-path "/store.org") :level . 1)
                           (,(concat cmacs-share-path "/ref.org") :level . 1))
      org-archive-location (concat cmacs-share-path "/archive/" (format-time-string "%Y-%m") ".org::"))

;; auto save on refile
(advice-add 'org-refile :after
        (lambda (&rest _)
        (org-save-all-org-buffers)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org-babel

;; don't ask for confirmation on org-babel evaluation
(setq org-confirm-babel-evaluate nil)

(customize-set-variable
 'org-babel-load-languages
 '(
   ;; (ammonite . t)
   (emacs-lisp . t)
   (elixir . t)
   (shell . t)
   (sql . t)
   (sqlite . t)
   (R . t)
   (http . t)
   (ein . t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org styling

;; Open file with all folded
(customize-set-variable 'org-startup-folded 'fold)
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
  (interactive)
  (set-face-attribute 'org-level-1 nil :height 1.0)
  (-map (lambda (x) (set-face-bold x nil))
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
         '("#abbdff"
           "#ffff55"
           "#90d6ff"
           "#ffc9e7"
           "#f1bc5c"
           "#62FCC4"
           "#cbc284"
           "#b9fc6d"))))
(org-faces-init)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org latex
(customize-set-variable
 'org-format-latex-options
 (plist-put org-format-latex-options :scale 1.5))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; my org functions

(defun org-append-link ()
  "Append link instead of replacing current point"
  (interactive)
  (insert " ")
  (call-interactively #'org-insert-link))

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

(defun find-or-create-olp
    (path)
  (condition-case err
      (goto-char (org-find-olp path t))
    (t
     (let ((err-msg (error-message-string err)))
       (string-match "Heading not found on level \\([0-9]+\\).*" err-msg)
       (let* ((level (string-to-number (match-string 1 err-msg)))
              (start-point (-take (dec level) path))
              (write-path (-drop (dec level) path))
              (demote? nil)
              (make-toplevel? nil))
         (if start-point
             (progn
               (goto-char (org-find-olp start-point t))
               (org-end-of-subtree)
               (when (string=
                      (-last-item start-point)
                      (nth 4 (org-heading-components)))
                 (setq demote? t)))
           (progn
             (setq make-toplevel? t)
             (end-of-buffer)))
         (dolist (heading write-path)
           (end-of-line)
           (comment-indent-new-line)
           (outline-insert-heading)
           (end-of-line)
           (insert heading)
           (when make-toplevel?
             (while (not (= (org-current-level) 1))
               (org-promote-subtree))
             (setq make-toplevel? nil))
           (if demote?
               (org-demote-subtree)
             (setq demote? t)))
         (save-buffer)
         (beginning-of-line))))))

(defun grab-daybook ()
  "If the daybook is outdated, log the old one, and generate a new one.
   Otherwise just go to the file"
  (interactive)
  (let ((workday (f-read-text (concat cmacs-share-path "/ref/workday.org"))))
    (find-file (concat cmacs-share-path "/daybook.org"))
    (beginning-of-buffer)
    (outline-next-heading)
    (let ((current-date (shell-command-to-string
                         "echo -n $(date '+%Y-%-m-%-d')"))
          (daybook-date (nth 4 (org-heading-components))))
      (when (not (string= daybook-date current-date))
        (org-demote-subtree)
        (org-demote-subtree)
        (next-line)
        (beginning-of-line)
        ;; TODO: set string to variable instead
        (evil-yank-characters (point) (point-max))
        ;; TODO: keep around uncompleted tasks under "goals"
        (evil-delete (point) (point-max))
        (beginning-of-buffer)
        (outline-next-heading)
        (org-promote-subtree)
        (org-promote-subtree)
        (org-edit-headline current-date)
        (end-of-line)
        (comment-indent-new-line)
        ;; TODO: have this dispatch on the day of the week
        (insert workday)
        (save-buffer)
        (find-file (concat cmacs-share-path "/daybook-log.org"))
        (find-or-create-olp (s-split "-" daybook-date))
        (end-of-line)
        (comment-indent-new-line)
        ;; TODO: insert from variable instead
        (yank)
        (save-buffer)
        (find-file (concat cmacs-share-path "/daybook.org"))))))

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

;; FIXME: conflicts below
(general-emacs-define-key org-mode-map
  [remap org-meta-return]   #'org-todo
  [remap org-return-indent] #'evil-window-down
  "M-h"                     #'outline-up-heading
  "M-i"                     #'org-id-get-create
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
 ("L"   #'org-append-link          "add link")
 ("m"   #'hydra-org-timer/body     "org timer")
 ("n"   #'org-narrow-to-subtree    "narrow")
 ("o"   #'org-sparse-tree-at-point "show all")
 ("O"   #'outline-show-all         "show all")
 ("r"   #'org-refile               "refile")
 ("t"   #'org-set-tags-command     "set tags")
 ("T"   #'hydra-org-table/body     "org table")
 ("e"   #'org-edit-special         "edit src")
 ("x"   #'org-latex-preview        "latex preview"))

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
  (list 'org-bullets-mode
        'org-indent-mode
        'visual-line-mode
        'prettify-mode))

(provide 'config/langs/org)

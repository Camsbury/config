(require 'prelude)
(require 'hydra)
(require 'core/env)
(require 'config/search)
(require 'config/langs/sql)
;; TODO: https://stackoverflow.com/questions/17478260/completely-hide-the-properties-drawer-in-org-mode
(require 'org-id)

(use-package ob-async)
(use-package ob-elixir)
(use-package ob-http)

(use-package org-bullets)

;; org hooks
(general-add-hook 'org-mode-hook
  (list 'org-bullets-mode
        'org-indent-mode
        'visual-line-mode
        'prettify-mode))

;; FIXME
(use-package org-download
  :config
  (customize-set-variable
   'org-download-screenshot-method
   "imagemagick/import"))
(use-package org-journal
  :config
  (customize-set-variable
   'org-journal-dir
   (concat cmacs-share-path "/journal/"))
  (customize-set-variable
   'org-journal-encrypt-journal
   t))

;; USEIT
(use-package org-ml)
;; USEIT
(use-package org-parser)
;; USEIT
(use-package org-ql)
(require 'config/langs/sql)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org alert

(use-package org-alert
  :config
  (setq
   alert-fade-time 180
   alert-default-style 'libnotify
   org-alert-interval 300
   org-alert-notify-cutoff 10
   org-alert-notify-after-event-cutoff 10
   org-alert-active-p t)
  (org-alert-enable))

(defun toggle-org-alerts ()
  (interactive)
  (if org-alert-active-p
      (progn
        (setq org-alert-active-p nil)
        (org-alert-disable)
        (message "org alerts disabled"))
      (progn
        (setq org-alert-active-p t)
        (org-alert-enable)
        (message "org alerts enabled"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org modules

(add-to-list 'org-modules 'org-habit t)
(add-to-list 'org-modules 'org-id t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org todos

(setq org-todo-keywords '((sequence "[ ]" "[x]")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org capture

(setq org-directory cmacs-share-path
      org-refile-use-outline-path t
      org-capture-templates
      `(("n" "Enqueue"
         entry (file+headline ,(concat cmacs-share-path "/org-roam/review.org.gpg") "inbox")
         "* [ ] %i%? %T")
        ("l" "Log action"
         entry (file+headline ,(concat cmacs-share-path "/org-roam/daybook.org.gpg") "log")
         "* %i%? %T"))
      org-refile-targets `((,(concat cmacs-share-path "/org-roam/projects.org.gpg") :level . 3)
                           (,(concat cmacs-share-path "/org-roam/tickler_list.org.gpg") :level . 1)
                           (,(concat cmacs-share-path "/org-roam/someday_maybe.org.gpg") :level . 1)
                           (,(concat cmacs-share-path "/org-roam/awaiting_action.org.gpg") :level . 1)
                           (,(concat cmacs-share-path "/org-roam/reference.org.gpg") :level . 1))
      org-archive-location (concat cmacs-share-path "/archive/" (format-time-string "%Y-%m") ".org::"))

;; auto save on refile
(advice-add 'org-refile :after
        (lambda (&rest _)
        (org-save-all-org-buffers)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; gtd

(setq org-tags-exclude-from-inheritance '("project")
      org-agenda-files `(,(concat cmacs-share-path "/org-roam/projects.org.gpg")
                         ,(concat cmacs-share-path "/org-roam/habit_tracker.org.gpg")))

(defun gtd--build-tags (tags selected fn)
  (ivy-read
   "Tag: "
   (append tags '("DONE"))
   :preselect "DONE"
   :action
   (lambda (tag)
     (if (string= "DONE" tag)
         (funcall fn selected)
       (let* ((selected (cons tag selected))
              (tags     (remove tag tags)))
         (gtd--build-tags tags selected fn))))))

(defun gtd--tagged-next-actions-view
    (tags)
  (org-tags-view t (s-join "|" tags)))

(defun gtd-projects ()
  (interactive)
  (org-tags-view nil "project"))

(defun gtd--tags->next-actions
    (filter-regex)
  (let* ((filter-fn (if filter-regex
                        (lambda (x) (s-matches? filter-regex x))
                      #'identity))
         (tags (->>
                (with-current-buffer
                    (find-file-noselect (car org-agenda-files))
                  (org-get-buffer-tags))
                (-map #'car)
                (-filter filter-fn))))
    (gtd--build-tags tags '() #'gtd--tagged-next-actions-view)))

(defun gtd-tags->next-actions ()
  (interactive)
  (gtd--tags->next-actions nil))

(defun gtd-contexts->next-actions ()
  (interactive)
  (gtd--tags->next-actions "c@"))

(defun gtd-projects->next-actions ()
  (interactive)
  (gtd--tags->next-actions "p@"))

(defun gtd-topics->next-actions ()
  (interactive)
  (gtd--tags->next-actions "t@"))

(defun gtd-search-mark-done ()
  (interactive)
  (let ((tasks (ht-create)))
    (org-map-entries
     (lambda ()
       (when (org-get-todo-state)
           (let ((pom (point)))
             (ht-set!
              tasks
              (buffer-substring pom (line-end-position))
              (copy-marker pom)))))
     nil
     'agenda)
    (ivy-read
     "Completed Task: "
     (ht-keys tasks)
     :action
     (lambda (task)
       (let ((m (ht-get tasks task)))
         (save-excursion
           (with-current-buffer (marker-buffer m)
             (goto-char m)
             (org-todo)
             ;; FIXME: this is too fast for some reason for the habit hooks
             (save-buffer))))))))

(defun gtd--get-org-mode-link-label (str)
  "Return the label of an org-mode link, or the string itself if it's not a link."
  (if (string-match "\\[\\[.*\\]\\[\\(.*\\)\\]\\]" str)
      (match-string 1 str)
    str))

(defun gtd-jump-to-project ()
  (interactive)
  (let ((projects (ht-create)))
    (org-map-entries
     (lambda ()
       (let ((pom (point)))
         (ht-set!
          projects
          (substring-no-properties
           (gtd--get-org-mode-link-label
            (org-get-heading t t)))
          (copy-marker pom))))
     "project"
     'agenda)
    (ivy-read
     "Project: "
     (ht-keys projects)
     :action
     (lambda (p)
       (let ((m (ht-get projects p)))
         (switch-to-buffer (marker-buffer m))
         (goto-char m)
         (evil-scroll-line-to-center)
         (org-show-subtree))))))

(defhydra hydra-gtd (:exit t :columns 5)
  "set register"
  ("SPC" #'toggle-org-alerts        "toggle org alerts")
  ;; ("P" #'gtd-projects->next-actions "projects->next-actions")
  ("P" #'gtd-projects               "projects list")
  ("c" #'gtd-contexts->next-actions "contexts->next-actions")
  ("e" #'gtd-search-mark-done       "search and mark done")
  ("l" #'org-agenda-list            "calendar")
  ("n" #'gtd-topics->next-actions   "topics->next-actions")
  ("o" (lambda ()
         (interactive)
         (spawn-right)
         (find-file (concat cmacs-config-path "/config/langs/org.el"))))
  ("p" #'gtd-jump-to-project        "jump to project")
  ("t" #'gtd-tags->next-actions     "tags->next-actions")

  ("q" nil))

(advice-add
 #'org-agenda-todo
 :after
 (lambda (&rest _)
   (org-save-all-org-buffers)))

(general-define-key :keymaps 'org-agenda-mode-map
                    "h" #'evil-backward-char
                    "j" #'org-agenda-next-line
                    "k" #'org-agenda-previous-line
                    "l" #'evil-forward-char)

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
;;; org roam

(use-package org-roam
  :config
  (customize-set-variable
   'org-roam-directory
   (concat cmacs-share-path "/org-roam"))
  (customize-set-variable
   'org-roam-capture-templates
   '(("n" "default" plain "%?"
      :target (file+head "${slug}.org.gpg"
                         "#+title: ${title}\n")
      :unnarrowed t)))
  (customize-set-variable 'epa-file-select-keys 1)
  (setq epa-file-encrypt-to '("camsbury7@gmail.com"))
  (org-roam-db-autosync-mode))

(use-package org-roam-dailies
  :after (org-roam)
  :config
  (customize-set-variable
   'org-roam-dailies-directory
   "daily/")
  (customize-set-variable
   'org-roam-dailies-capture-templates
   '(("d" "default" entry
      "* %?"
      :target (file+head "%<%Y-%m-%d>.org.gpg"
                         "#+title: %<%Y-%m-%d>\n")))))


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

(defun org-add-extant-tags ()
  "Add tags based on those that already exist"
  (interactive)
  (let* ((selected (org-get-tags nil t))
         (tags (->>
                (with-current-buffer
                    (find-file-noselect (car org-agenda-files))
                  (org-get-buffer-tags))
                (-map #'car)
                (-remove (lambda (x) (-contains? selected x))))))
    (gtd--build-tags tags selected #'org-set-tags)))

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
 ("I"   #'org-new-item             "new item")
 ("L"   #'org-append-link          "add link")
 ("O"   #'outline-show-all         "show all")
 ("T"   #'hydra-org-table/body     "org table")
 ("Y"   #'org-roam-dailies-find-next-note)
 ("a"   #'org-archive-subtree      "archive")
 ("d"   #'org-deadline             "deadline")
 ("e"   #'org-edit-special         "edit src")
 ("g"   #'org-add-extant-tags      "add extant tags")
 ("i"   #'org-roam-node-insert     "insert roam node")
 ("l"   #'hydra-org-link/body      "org links")
 ("m"   #'hydra-org-timer/body     "org timer")
 ("n"   #'org-narrow-to-subtree    "narrow")
 ("o"   #'org-sparse-tree-at-point "show all")
 ("r"   #'org-refile               "refile")
 ("t"   #'counsel-org-tag          "set tags")
 ("v"   (lambda ()
          (interactive)
          (org-cycle-set-startup-visibility)) "reset viz")
 ("x"   #'org-latex-preview        "latex preview")
 ("y"   #'org-roam-dailies-find-previous-note))

(defhydra hydra-visual-org (:exit t)
  "org-mode"
 ("s" #'org-sort "sort"))

(general-def org-src-mode-map
 [remap empty-mode-leader] #'hydra-org-src/body)

(defhydra hydra-org-src (:exit t)
  "org-src-mode"
  ("q" #'org-edit-src-exit "write and quit")
  ("k" #'org-edit-src-abort "quit without saving"))

(provide 'config/langs/org)

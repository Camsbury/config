;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'hydra)
(require 'core/env)
(require 'config/search)
(require 'config/langs/sql)
;; TODO: https://stackoverflow.com/questions/17478260/completely-hide-the-properties-drawer-in-org-mode
(require 'org-id)
;; org owns org-capture-templates, set in the capture block below.
(declare-vars org-capture-templates)
(defvar org-alert-active-p nil
  "Non-nil when org-alert notifications are enabled.
Toggled by `ck/toggle-org-alerts'.")

(use-package ob-async)
(use-package ob-elixir)
(use-package ob-http)

(use-package org-bullets)

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
   org-alert-interval 300
   org-alert-notify-cutoff 10
   org-alert-notify-after-event-cutoff 10
   org-alert-active-p t)
  (add-hook 'exwm-init-hook
            (lambda () (run-with-timer 5 nil #'org-alert-enable)))
  )

(defun ck/toggle-org-alerts ()
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
        ("b" "To buy"
         entry (file+headline ,(concat cmacs-share-path "/org-roam/to_blah.org.gpg") "to buy")
         "* %i%? %T")
        ("l" "Log action"
         entry (file+headline ,(concat cmacs-share-path "/org-roam/daybook.org.gpg") "log")
         "* %i%? %T"))
      org-refile-targets `((,(concat cmacs-share-path "/org-roam/projects.org.gpg") :level . 3)
                           (,(concat cmacs-share-path "/org-roam/tickler.org.gpg") :level . 1)
                           (,(concat cmacs-share-path "/org-roam/someday_maybe.org.gpg") :level . 1)
                           (,(concat cmacs-share-path "/org-roam/awaiting_action.org.gpg") :level . 1)
                           (,(concat cmacs-share-path "/org-roam/reference.org.gpg") :level . 1))
      org-archive-location (concat cmacs-share-path "/archive/" (format-time-string "%Y-%m") ".org::"))

(advice-add 'org-refile :after
        (lambda (&rest _)
        (org-save-all-org-buffers)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org-babel

(setq org-confirm-babel-evaluate nil)

(customize-set-variable
 'org-babel-load-languages
 '(
   (emacs-lisp . t)
   (elixir . t)
   (shell . t)
   (sql . t)
   (sqlite . t)
   (R . t)
   (http . t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org styling

(customize-set-variable 'org-startup-folded 'fold)
;; Don't use subpar references
(setq org-table-use-standard-references nil)
;; Keep blank lines from being sucked into folds
(setq org-cycle-separator-lines -1)
(setq org-list-allow-alphabetical 1)
(setq org-ellipsis " ▾")
(setq org-bullets-bullet-list '("•"))
(defun ck/org-faces-init ()
  "Set org heading faces: level 1 at normal height, none bold, fixed colors."
  (interactive)
  (set-face-attribute 'org-level-1 nil :height 1.0)
  (-each '( org-level-1
            org-level-2
            org-level-3
            org-level-4
            org-level-5
            org-level-6
            org-level-7
            org-level-8)
    (lambda (x) (set-face-bold x nil)))
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
(ck/org-faces-init)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org latex

(customize-set-variable
 'org-format-latex-options
 (plist-put org-format-latex-options :scale 1.5))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; my org functions

(defun ck/org-append-link ()
  "Insert a link after point instead of replacing what is at point."
  (interactive)
  (insert " ")
  (call-interactively #'org-insert-link))

(defun ck/org-table-clear-and-align ()
  "Clear a cell, then align the table."
  (interactive)
  (org-table-blank-field)
  (org-table-align))

(defun ck/org-table-edit-and-align ()
  "Edit a cell, then align the table."
  (interactive)
  (call-interactively 'org-table-edit-field)
  (org-table-align))

(defun ck/org-insert-heading ()
  "Open a line below and start a heading there."
  (interactive)
  (call-interactively #'evil-open-below)
  (if (org-current-level)
      (call-interactively #'outline-insert-heading)
    (insert "* ")))

(defun ck/org-insert-todo-heading ()
  "Open a line below, start a heading there, and set its TODO state."
  (interactive)
  (call-interactively #'evil-open-below)
  (if (org-current-level)
      (call-interactively #'outline-insert-heading)
    (insert "* "))
  (call-interactively #'org-todo))

(defun ck/org-cycle-shallow (&optional arg)
  "Toggle folding of the heading at point only, not its whole subtree."
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

(defun ck/org-sparse-tree-at-point ()
  "Fold the buffer, then reveal only the context around point."
  (interactive)
  (org-overview)
  (org-fold-show-context))

(defun ck/org-new-item ()
  "Open a line below and start a list item there."
  (interactive)
  (call-interactively #'evil-open-below)
  (call-interactively #'org-insert-item))

(defun ck/org-add-extant-tags ()
  "Set tags on this entry, choosing from the tags the agenda file already uses."
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
;; Child modules: org-roam stack, bindings/hydras

(m-require config/langs/org
  roam
  keys)

(provide 'config/langs/org)

;; use-package config: forward-refs deferred org-alert/vertico-posframe helpers
;; and gtd--build-tags (defined in the gtd module), invoked only at runtime.
;; Suppress just the unresolved class.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

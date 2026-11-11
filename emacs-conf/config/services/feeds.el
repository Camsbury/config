;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'core/env)

(defvar ck/elfeed-views
  '(("general" . "@6months +unread -dyal")
    ("dyal"    . "@1-week-ago +unread +dyal"))
  "Alist of view name to elfeed search filter, offered by
`ck/elfeed-select-view'. The first view is the default filter.
Feed tags come from the headings in feeds.org; the Dyal heading tags
its feeds `dyal'. Add a view by adding a pair here.")

(use-package elfeed
  :config
  (customize-set-variable 'elfeed-search-filter (cdar ck/elfeed-views))
  (define-key elfeed-search-mode-map "v" #'ck/elfeed-select-view)
  (add-hook 'elfeed-new-entry-hook #'ck/elfeed-merge-duplicate t))
(use-package elfeed-score
  :after (elfeed)
  :init
  (customize-set-variable 'elfeed-score-serde-score-file (concat cmacs-share-path "/feeds.score"))
  :config
  (evil-set-initial-state 'elfeed-show-mode 'emacs)
  (evil-set-initial-state 'elfeed-search-mode 'emacs)
  (elfeed-score-enable)
  (define-key elfeed-search-mode-map "." elfeed-score-map))
(use-package elfeed-org
  :after (elfeed)
  :config
  (elfeed-org)
  (setq rmh-elfeed-org-files `(,(concat cmacs-share-path "/feeds.org"))))

(defvar ck/elfeed--first-entry-by-link nil
  "Hash table from an article link to the id of its first elfeed entry.
Built from the database on first use, then kept current by
`ck/elfeed-merge-duplicate'.")

(defun ck/elfeed--link-index (new-entry)
  "Return the link index, building it from the database if needed.
NEW-ENTRY is already in the database when the new-entry hook runs, so
the build leaves it out; otherwise it could index itself as the first."
  (or ck/elfeed--first-entry-by-link
      (let ((index (make-hash-table :test #'equal))
            (new-id (elfeed-entry-id new-entry)))
        ;; The visit runs newest first, so the oldest entry wins a link.
        (with-elfeed-db-visit (entry _feed)
          (let ((link (elfeed-entry-link entry)))
            (when (and link (not (equal (elfeed-entry-id entry) new-id)))
              (puthash link (elfeed-entry-id entry) index))))
        (setq ck/elfeed--first-entry-by-link index))))

(defun ck/elfeed-merge-duplicate (entry)
  "Fold ENTRY into an earlier entry that links to the same article.
The earlier entry gains ENTRY's tags except `unread', and ENTRY is
marked read, so a story seen in two feeds shows once with both feeds'
tags. Nothing is deleted."
  (when-let* ((link (elfeed-entry-link entry)))
    (let* ((index (ck/elfeed--link-index entry))
           (first (elfeed-db-get-entry (gethash link index))))
      (if (and first (not (equal (elfeed-entry-id first)
                                 (elfeed-entry-id entry))))
          (progn
            (apply #'elfeed-tag first
                   (remq 'unread (elfeed-entry-tags entry)))
            (elfeed-untag entry 'unread))
        (puthash link (elfeed-entry-id entry) index)))))

(defun ck/elfeed-open ()
  "Open elfeed on the default view and refresh all feeds."
  (interactive)
  (elfeed)
  (elfeed-search-set-filter (cdar ck/elfeed-views))
  (elfeed-update))

(defun ck/elfeed-select-view ()
  "Pick a view from `ck/elfeed-views' and show it in elfeed.
From outside elfeed, this also opens elfeed and refreshes all feeds."
  (interactive)
  (let* ((choice (completing-read "Feed view: "
                                  (mapcar #'car ck/elfeed-views) nil t))
         (filter (alist-get choice ck/elfeed-views nil nil #'string=))
         (opening (not (derived-mode-p 'elfeed-search-mode))))
    (elfeed)
    (elfeed-search-set-filter filter)
    (when opening
      (elfeed-update))))

(provide 'config/services/feeds)

;; use-package config file: elfeed/elfeed-score/elfeed-org and
;; `evil-set-initial-state' are the packages' own API, invoked only at runtime.
;; Suppress just the unresolved class; every other class stays live.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

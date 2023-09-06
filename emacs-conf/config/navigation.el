(require 'prelude)
(require 'core/env)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun xdg-open (l-name)
  "Open a link interactively"
  (interactive)
  (shell-command
   (concat "xdg-open \"" (alist-get l-name my-links) "\"")))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bookmarks

;; stop annoying prompts about reloading bookmarks
(customize-set-variable 'bookmark-watch-bookmark-file nil)

(defun bookmark-set-and-save ()
  "set and save bookmark"
  (interactive)
  (bookmark-set)
  (bookmark-save))

(defun bookmark-clear ()
  "clear all bookmarks"
  (interactive)
  (-> bookmark-end-of-version-stamp-marker
      (concat "()")
      (f-write-text 'utf-8 bookmark-default-file))
  (bookmark-load bookmark-default-file))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Nav Functions

;; TODO: review these for useful info
(setq file-links
      `(:books         ,(concat cmacs-share-path  "/org-roam/books.org.gpg")
        :brain-dump    ,(concat cmacs-share-path  "/ref/dump.org")
        :habits        ,(concat cmacs-share-path  "/habits.org")
        :journal       ,(concat cmacs-share-path  "/journal.org")
        :links         ,(concat cmacs-share-path  "/ref/links.org")
        :notes         "/tmp/notes.org"
        :review        ,(concat cmacs-share-path  "/org-roam/review.org.gpg")
        :runs          ,(concat cmacs-share-path  "/ref/runs.org")
        :se-principles ,(concat cmacs-share-path  "/ref/software_engineering.org")
        :systems       ,(concat cmacs-share-path  "/systems.org")))

(defun open-file-link (file-key)
  "Open a file link interactively"
  (interactive)
  (->> file-key
    (plist-get file-links)
    find-file))

(defun open-new-tmp (arg)
  "Opens a new tmp file"
  (interactive "sFile name: ")
  (find-file (concat "/tmp/" arg)))

(defun open-project-summary ()
  "Opens the project's summary file"
  (interactive)
  (->> (f-relative (projectile-project-root) "~")
       (f-join (concat cmacs-share-path "/summaries"))
       (s-append "summary.org")
       (find-file)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Spawn Functions

(defun spawn-below ()
  "Spawns a window below"
  (interactive)
  (split-window-below)
  (windmove-down))

(defun spawn-right ()
  "Spawns a window to the right"
  (interactive)
  (split-window-right)
  (windmove-right))

(defun spawn-file-link (file-key)
  "Spawn a window to the right before calling a function"
  (interactive)
  (split-window-right)
  (windmove-right)
  (open-file-link file-key))

(defun spawnify (f)
  "Spawn a window to the right before calling a function"
  (interactive)
  (split-window-right)
  (windmove-right)
  (call-interactively f))

(defun spawn-new (arg)
  "Spawns a new fundamental buffer"
  (interactive "sBuffer name: ")
  (spawn-right)
  (switch-to-buffer (generate-new-buffer-name arg)))

(provide 'config/navigation)

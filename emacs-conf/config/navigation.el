;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'core/env)
(require 'config/search)

;; Host-provided link registries consumed by the openers below; declared so
;; referencing them here is not a free-variable warning.
(declare-vars my-links file-links)
;; vertico-posframe (deferred) leaks a noruntime reference through the
;; config/search require chain; declare it so the compile stays clean.
(declare-functions "vertico-posframe" vertico-posframe-mode-workable-p)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ck/xdg-open (l-name)
  "Open a link interactively"
  (interactive)
  (shell-command
   (concat "xdg-open \"" (alist-get l-name my-links) "\"")))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bookmarks

;; stop annoying prompts about reloading bookmarks
(customize-set-variable 'bookmark-watch-bookmark-file nil)

(defun ck/bookmark-set-and-save ()
  "set and save bookmark"
  (interactive)
  (bookmark-set)
  (bookmark-save))

(defun ck/consult-bookmark-and-save ()
  "set and save bookmark"
  (interactive)
  (call-interactively #'consult-bookmark)
  (bookmark-save))

(defun ck/bookmark-clear ()
  "clear all bookmarks"
  (interactive)
  (setq bookmark-alist ())
  (-> bookmark-end-of-version-stamp-marker
      (concat "()")
      (f-write-text 'utf-8 bookmark-default-file))
  (bookmark-load bookmark-default-file))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Nav Functions

(defun ck/open-file-link (file-key)
  "Open a file link interactively"
  (interactive)
  (->> file-key
    (plist-get file-links)
    find-file))

(defun ck/open-new-tmp (arg)
  "Opens a new tmp file"
  (interactive "sFile name: ")
  (find-file (concat "/tmp/" arg)))

(defun ck/open-project-summary ()
  "Opens the project's summary file"
  (interactive)
  (->> (f-relative (projectile-project-root) "~")
       (f-join (concat cmacs-share-path "/summaries"))
       (s-append "summary.org")
       (find-file)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Spawn Functions

(defun ck/spawn-below ()
  "Spawns a window below"
  (interactive)
  (split-window-below)
  (windmove-down))

(defun ck/spawn-right ()
  "Spawns a window to the right"
  (interactive)
  (split-window-right)
  (windmove-right))

(defun ck/spawn-file-link (file-key)
  "Spawn a window to the right before calling a function"
  (interactive)
  (split-window-right)
  (windmove-right)
  (ck/open-file-link file-key))

(defun ck/spawnify (f)
  "Spawn a window to the right before calling a function"
  (interactive)
  (split-window-right)
  (windmove-right)
  (call-interactively f))

(defun ck/spawn-new (arg)
  "Spawns a new fundamental buffer"
  (interactive "sBuffer name: ")
  (ck/spawn-right)
  (switch-to-buffer (generate-new-buffer-name arg)))

(provide 'config/navigation)

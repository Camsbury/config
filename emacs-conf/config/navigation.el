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

;; Vertical-band tiling model (decision 0010): the frame is a row of
;; full-height vertical bands.  A band may hold at most ONE top/bottom
;; (stacked) split, scoped to that band.  `ck/spawn-right' therefore splits
;; at the BAND level, so a stacked band shifts as a unit and a new band opens
;; beside it (never nesting a pane inside the current one); `ck/spawn-below'
;; refuses to stack a band that is already split.

(defun ck/band-window (&optional window)
  "Return the vertical-band subtree window containing WINDOW.
Walks up past any top/bottom (vertical) combination and stops at the
child of the row-of-bands, or at the frame root when no bands exist yet.
`window-left-child' is non-nil only for a left/right combination, so it
is the test for \"parent is the row of bands\"."
  (let ((w (or window (selected-window))))
    (while (let ((p (window-parent w)))
             (and p (not (window-left-child p))))
      (setq w (window-parent w)))
    w))

(defun ck/spawn-below ()
  "Spawn a window below, within the current band.
Enforces the one-split-per-band rule: refuses when the band is already
a top/bottom stack (`window-top-child' of the band is non-nil)."
  (interactive)
  (when (window-top-child (ck/band-window))
    (user-error "Band already has a top/bottom split"))
  (split-window-below)
  (windmove-down))

(defun ck/spawn-right ()
  "Open a new vertical band to the right of the current band.
Splits at the band level (`ck/band-window'), so a stacked (top/bottom)
band shifts as a unit instead of nesting a new pane inside the current
one.  `split-window' on an internal band window drops a new live window
beside the whole subtree; select it so callers act in the new band."
  (interactive)
  (select-window (split-window (ck/band-window) nil 'right)))

(defun ck/spawn-file-link (file-key)
  "Spawn a new vertical band before opening FILE-KEY in it."
  (interactive)
  (ck/spawn-right)
  (ck/open-file-link file-key))

(defun ck/spawnify (f)
  "Spawn a new vertical band before calling F in it."
  (interactive)
  (ck/spawn-right)
  (call-interactively f))

(defun ck/spawn-new (arg)
  "Spawns a new fundamental buffer"
  (interactive "sBuffer name: ")
  (ck/spawn-right)
  (switch-to-buffer (generate-new-buffer-name arg)))

(provide 'config/navigation)

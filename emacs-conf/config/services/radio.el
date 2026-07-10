;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'core/env)
(require 'hydra)

;; emms owns these; declared special so the setqs below compile clean.
(declare-vars emms-info-asynchronously
              emms-info-functions
              emms-repeat-playlist
              emms-track-description-function)

(use-package emms-setup
  :init
  (setq emms-player-list '(emms-player-vlc))
  (setq emms-info-asynchronously nil)
  (setq emms-playlist-buffer-name "*Radio*")
  :config
  (emms-all)
  (setq emms-info-functions '(emms-info-cueinfo))
  (setq emms-repeat-playlist t)
  (setq emms-track-description-function #'ck/radio-track-description))

(defun ck/emms-strong-pause ()
  "Stop playlists that pause won't stop."
  (interactive)
  (if emms-player-playing-p
      (emms-stop)
    (emms-start)))

(defvar ck/radio--playlists nil
  "Cache of radio.edn: hash of playlist keyword to (url to title) hash.
Nil until first read; `ck/radio-playlists' fills it lazily.")

(defun ck/radio-reload ()
  "Read radio.edn from `cmacs-share-path' and return the playlist table."
  (interactive)
  (let ((file (concat cmacs-share-path "/music/radio.edn")))
    (unless (file-readable-p file)
      (user-error "No readable radio.edn at %s" file))
    (setq ck/radio--playlists
          (parseedn-read-str (f-read file 'utf-8)))))

(defun ck/radio-playlists ()
  "Return the playlist table, reading radio.edn on first use."
  (or ck/radio--playlists (ck/radio-reload)))

(defvar ck/radio--track-titles (make-hash-table :test 'equal)
  "Titles for inserted radio tracks, keyed by track URL.
Filled by `ck/open-radio-playlist'; read by `ck/radio-track-description',
which emms calls long after insertion (modeline, notifications), so the
titles must outlive the insert.")

(defun ck/radio-track-description (track)
  "Describe TRACK by its radio.edn title, else the emms default."
  (or (gethash (emms-track-name track) ck/radio--track-titles)
      (emms-track-simple-description track)))

(defun ck/open-radio-playlist (playlist-key)
  "Load the radio playlist named PLAYLIST-KEY (a keyword) and start it.
Interactively, pick the playlist by name from radio.edn."
  (interactive
   (let ((names nil))
     (maphash (lambda (key _tracks)
                (push (cons (substring (symbol-name key) 1) key) names))
              (ck/radio-playlists))
     (list (cdr (assoc (completing-read "Playlist: " names nil t) names)))))
  (let ((playlist (gethash playlist-key (ck/radio-playlists))))
    (unless playlist
      (user-error "No radio playlist %s" playlist-key))
    (with-current-buffer
        (or (get-buffer emms-playlist-buffer-name)
            (emms-playlist-new))
      (emms-playlist-clear)
      (maphash
       (lambda (track-url title)
         (puthash track-url title ck/radio--track-titles)
         (emms-playlist-insert-track (emms-track 'url track-url)))
       playlist)
      (emms-random))))

(defun ck/open-hits-playlist ()
  "Open the hits radio playlist."
  (interactive)
  (ck/open-radio-playlist :hits))

(defun ck/open-rock-playlist ()
  "Open the rock radio playlist."
  (interactive)
  (ck/open-radio-playlist :rock))

(defhydra hydra-radio (:exit t :columns 5)
  "radio"
  ("SPC" #'ck/emms-strong-pause       "pause/play")
  ("o"   #'ck/open-radio-playlist     "open playlist by name")
  ("h"   #'ck/open-hits-playlist      "open hits playlist")
  ("r"   #'ck/open-rock-playlist      "open rock playlist")
  ("v"   (switch-to-buffer "*Radio*") "view radio playlist")
  ("s"   #'emms-random                "random station/track")
  ("["   #'emms-previous              "previous station/track")
  ("]"   #'emms-next                  "next station/track")
  ("Q"   #'emms-stop                  "quit radio")
  ("q" nil))

(provide 'config/services/radio)

;; use-package/hydra file: the emms-* commands are the package's own API,
;; invoked only at runtime.  Suppress just the unresolved class; every other
;; class stays live.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

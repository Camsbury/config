(use-package emms-setup
  :init
  (setq emms-player-list '(emms-player-vlc))
  (setq emms-info-asynchronously nil)
  (setq emms-playlist-buffer-name "*Radio*")
  :config
  (emms-all))

(defun emms-strong-pause ()
  "Stops playlists that pause won't stop"
  (interactive)
  (if emms-player-playing-p
      (emms-stop)
    (emms-start)))

(setq radio-playlists
      '(:rock "~/Dropbox/lxndr/music/rock.pls"
        :hits "~/Dropbox/lxndr/music/hits.pls"))

(setq radio-current-playlist-info '())

(defun -get-playlist-info ()
  (interactive)
  (let ((name-by-file '())
        (nums-and-files  '()))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^File\\([0-9]*\\)=\\(.+\\)$" nil t)
        (setq nums-and-files
              (cons (vector (match-string 1) (match-string 2)) nums-and-files)))
      (goto-char (point-min))
      (dolist (num-and-file nums-and-files)
        (re-search-forward
         (concat "^Title" (aref num-and-file 0) "=\\(.+\\)$")
         nil t)
        (setq name-by-file
              (->> name-by-file
                (cons (match-string 1))
                (cons (aref num-and-file 1))))
        (goto-char (point-min))))
    name-by-file))

(defun get-playlist-info (playlist-key)
  "get the info for a playlist"
  (with-temp-buffer
    (emms-insert-file-contents (plist-get radio-playlists playlist-key))
    (goto-char (point-min))
    (when (not (emms-source-playlist-pls-p))
      (error "Not a pls playlist file."))
    (-get-playlist-info)))

(customize-set-variable
 'emms-track-description-function
 (lambda (track)
   "describe the current track"
   (lax-plist-get radio-current-playlist-info (emms-track-name track))))

(defun open-playlist (playlist-key)
  "Play my playlist by name"
  (interactive)
  (setq radio-current-playlist-info (get-playlist-info playlist-key))
  (emms-play-pls-playlist (plist-get radio-playlists playlist-key))
  (setq emms-repeat-playlist t)
  (emms-random))

(provide 'services/radio)

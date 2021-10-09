(require 'prelude)
(require 'core/env)

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
      (-> (concat cmacs-share-path "/music/radio.edn")
        (f-read 'utf-8)
        parseedn-read-str))

(define-emms-source radio-playlist (playlist-key)
  ;; set the description function
  (customize-set-variable
   'emms-track-description-function
   (lambda (track)
     (->> radio-playlists
       (gethash playlist-key)
       (gethash (emms-track-name track)))))
  ;; build the playlist
  (maphash
   (lambda (track-url _title)
     (let ((track
            (if (string-match "\\`\\(http[s]?\\|mms\\)://" track-url)
                (emms-track 'url track-url)
              (if (string-match "\\`file://" track-url) ;; handle file:// uris
                  (let ((track-url (url-unhex-string (substring track-url 7))))
                    (emms-track 'track-url track-url))
                (emms-track 'track-url (expand-file-name track-url dir))))))
       (emms-playlist-insert-track track)))
   (gethash playlist-key radio-playlists)))

(defun open-playlist (playlist-key)
  "Play my playlist by name"
  (interactive)
  (emms-play-radio-playlist playlist-key)
  (setq emms-repeat-playlist t)
  (emms-random))

(provide 'config/services/radio)

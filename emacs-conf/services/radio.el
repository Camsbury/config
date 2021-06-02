(use-package emms-setup
  :init
  (setq emms-player-list '(emms-player-vlc))
  (setq emms-info-asynchronously nil)
  (setq emms-playlist-buffer-name "*Radio*")
  :config
  (emms-all))


;; update these source functions to pull in the track name for the playlist buffer
;; probably parse out the name and set it on the track
;; emms-source-playlist-parse-pls
;; emms-source-playlist-pls-files

(defun emms-strong-pause ()
  "Stops playlists that pause won't stop"
  (interactive)
  (if emms-player-playing-p
      (emms-stop)
    (emms-start)))

(defun open-radio ()
  "Play my custom radio"
  (interactive)
  (emms-play-pls-playlist "~/Dropbox/lxndr/music/radio.pls")
  (setq emms-repeat-playlist t))

(provide 'services/radio)

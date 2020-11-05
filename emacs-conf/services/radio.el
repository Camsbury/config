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

(defun open-radio ()
  "Play my custom radio"
  (emms-play-pls-playlist "~/Dropbox/lxndr/music/radio.pls")
  (emms-toggle-repeat-playlist))

(provide 'services/radio)

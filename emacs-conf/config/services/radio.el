(require 'prelude)
(require 'core/env)
(require 'hydra)

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

(defun open-playlist (playlist-key)
  "Play my playlist by name"
  (with-current-buffer
      (or (get-buffer emms-playlist-buffer-name)
          (emms-playlist-new))
    (emms-playlist-clear)
    (let* ((emms-info-functions '(emms-info-cueinfo))
           (radio-playlist (gethash playlist-key radio-playlists))
           (emms-track-description-function
            (lambda (track)
              (or (gethash (emms-track-name track) radio-playlist)
                  "(no name)"))))
      (maphash
       (lambda (track-url _title)
         ;; NOTE: can try to insert this buffer local path before the url, which is annoying.
         (let ((track (emms-track 'url track-url)))
           (emms-playlist-insert-track track)))
       radio-playlist)
      (setq emms-repeat-playlist t)
      (emms-random))))

(defhydra hydra-radio (:exit t :columns 5)
  "radio"
  ("SPC" #'emms-strong-pause          "pause/play")
  ("h"   (lambda ()
           (interactive)
           (open-playlist :hits))     "open hits playlist")
  ("r"   (lambda ()
           (interactive)
           (open-playlist :rock))     "open rock playlist")
  ("v"   (switch-to-buffer "*Radio*") "view radio playlist")
  ("s"   #'emms-random                "random station/track")
  ("["   #'emms-previous              "previous station/track")
  ("]"   #'emms-next                  "next station/track")
  ("Q"   #'emms-stop                  "quit radio")
  ("q" nil))

(provide 'config/services/radio)


(comment

 (cancel-debug-on-entry 'emms-track-simple-description)
 (cancel-debug-on-entry 'open-playlist)
 (emms-playlist-insert-track
  (emms-track 'url "https://stream.revma.ihrhls.com/zc3401/hls.m3u8"))
 )

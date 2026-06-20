;; -*- lexical-binding: t; -*-
(defun ck/url->uri (url)
  "Transform a Spotify URL to a URI"
  (->> url
       (s-replace "https://open.spotify.com/" "spotify:")
       (s-replace "/" ":")
       (s-replace-regexp "\?.*" "")))

(defun ck/open-spotify-uri (uri)
  "opens a Spotify URI"
  (shell-command
   (concat "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
/org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.OpenUri string:" uri)))

(defun ck/open-spotify-url (url)
  "Opens an HTTPS Spotify link in the client"
  (interactive "sSpotify URL: ")
  (-> url
      ck/url->uri
      ck/open-spotify-uri))

(provide 'config/services/spotify)

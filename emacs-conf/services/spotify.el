(defun url->uri (url)
  "Transform a Spotify URL to a URI"
  (->> url
       (s-replace "https://open.spotify.com/" "spotify:")
       (s-replace "/" ":")
       (s-replace-regexp "\?.*" "")))

(defun open-spotify-uri (uri)
  "opens a Spotify URI"
  (shell-command
   (concat "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
/org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.OpenUri string:" uri)))

(defun open-spotify-url (url)
  "Opens an HTTPS Spotify link in the client"
  (interactive "sSpotify URL: ")
  (-> url
      url->uri
      open-spotify-uri))

(provide 'services/spotify)

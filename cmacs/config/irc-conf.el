(require 'private-conf)

(setq circe-sasl-username circe-sasl-username-private)
(setq circe-sasl-password circe-sasl-password-private)
(setq irc-debug-log t)
(setq circe-network-options
      `(("Freenode"
         :tls t
         :port 6697
         :nick "camsbury"
         :sasl-username ,circe-sasl-username
         :sasl-password ,circe-sasl-password
         :channels ("#nixos" "#emacs" "#haskell" "#emacs-circe"))))

(provide 'irc-conf)

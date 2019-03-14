(require 'private-conf)

(setq irc-debug-log t)
(setq circe-network-options
      '(("Freenode"
         :use-tls t
         :port 6667
         :nick "camsbury"
         :sasl-username circe-sasl-username-private
         :sasl-password circe-sasl-password-private
         :channels ("#nixos" "#emacs" "#haskell" "#emacs-circe")
         )))
(setq circe-sasl-username circe-sasl-username-private)
(setq circe-sasl-password circe-sasl-password-private)

(provide 'irc-conf)

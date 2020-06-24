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
         :channels (
                    ;; "#bash"
                    ;; "##c"
                    ;; "#docker"
                    ;; "#emacs"
                    ;; "#emacs-circe"
                    ;; "#git"
                    ;; "#hardware"
                    ;; "#haskell"
                    ;; "#javascript"
                    ;; "##math"
                    ;; "##networking"
                    "#nixos"
                    ;; "#postgresql"
                    ;; "#python"
                    ;; "##security"
                    "##tvl"))))

(provide 'irc-conf)

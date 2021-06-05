(use-package circe
  :config
  (setq irc-sasl-username (getenv "SASL_USERNAME"))
  (setq freenode-sasl-password (getenv "FREENODE_PASSWORD"))
  (setq hackint-sasl-password (getenv "HACKINT_PASSWORD"))
  (setq libera-sasl-password (getenv "LIBERA_PASSWORD"))
  (setq irc-debug-log t)
  (add-to-list
   'circe-network-defaults
   '("Libera"
     :host "irc.libera.chat"
     :port (6667 . 6697)
     :nickserv-mask "^NickServ!NickServ@services\\.$"
     :nickserv-identify-challenge "\C-b/msg\\s-NickServ\\s-identify\\s-<password>\C-b"
     :nickserv-identify-command "PRIVMSG NickServ :IDENTIFY {nick} {password}"
     :nickserv-identify-confirmation "^You are now identified for .*\\.$"
     :nickserv-ghost-command "PRIVMSG NickServ :GHOST {nick} {password}"
     :nickserv-ghost-confirmation "has been ghosted\\.$\\|is not online\\.$"))
  (add-to-list
   'circe-network-defaults
   '("HackInt"
     :host "irc.hackint.org"
     :port 6697
     :nickserv-mask "^NickServ!NickServ@services\\.$"
     :nickserv-identify-challenge "\C-b/msg\\s-NickServ\\s-identify\\s-<password>\C-b"
     :nickserv-identify-command "PRIVMSG NickServ :IDENTIFY {nick} {password}"
     :nickserv-identify-confirmation "^You are now identified for .*\\.$"
     :nickserv-ghost-command "PRIVMSG NickServ :GHOST {nick} {password}"
     :nickserv-ghost-confirmation "has been ghosted\\.$\\|is not online\\.$"))
  (setq circe-network-options
        `(("HackInt"
           :tls t
           :nick "camsbury"
           ;; :sasl-username ,irc-sasl-username
           ;; :sasl-password ,hackint-sasl-password
           :channels ("#tvl"))
          ("Libera"
           :tls t
           :nick "camsbury"
           :sasl-username ,irc-sasl-username
           :sasl-password ,libera-sasl-password
           :channels ("#nixos"))
          ("Freenode"
           :tls t
           :port 6697
           :nick "camsbury"
           :sasl-username ,irc-sasl-username
           :sasl-password ,freenode-sasl-password
           :channels (;; "#bash"
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
                      ;; "#postgresql"
                      ;; "#python"
                      ;; "##security"
                      )))))
(use-package circe-notifications
  :after (circe)
  :config
  (autoload 'enable-circe-notifications "circe-notifications" nil t)
  (eval-after-load "circe-notifications"
    '(setq circe-notifications-watch-strings '()))
  (add-hook 'circe-server-connected-hook 'enable-circe-notifications))

(defun join-irc ()
  (interactive)
  (circe "HackInt")
  (circe "Libera"))

(provide 'services/irc)

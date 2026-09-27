;; -*- lexical-binding: t; -*-
(require 'prelude)

;; `circe' is deferred; declare the one command `ck/join-irc' calls at runtime.
(declare-functions "circe" circe)

(defun ck/irc-password (host)
  "The SASL password for HOST from auth-source."
  (auth-source-pick-first-password :host host))

(use-package circe
  :config
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
        '(("HackInt"
           :tls t
           :nick "camsbury"
           :channels ("#tvl"))
          ("Libera"
           :tls t
           :nick "camsbury"
           :sasl-username "camsbury"
           :sasl-password ck/irc-password
           :channels ("#nixos")))))
(use-package circe-notifications
  :after (circe)
  :config
  (autoload 'enable-circe-notifications "circe-notifications" nil t)
  (eval-after-load "circe-notifications"
    '(setq circe-notifications-watch-strings '()))
  (add-hook 'circe-server-connected-hook 'enable-circe-notifications))

(defun ck/join-irc ()
  "Jump into all your favorite channels"
  (interactive)
  (circe "HackInt")
  (circe "Libera"))

(provide 'config/services/irc)

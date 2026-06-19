;; -*- lexical-binding: t; -*-
;; Durable Emacs server so the running WM is always reachable via `emacsclient'
;; (live inspection/eval, editor integration, opening files from terminals).
;;
;; The socket lives under /run/user/<uid>/emacs (mode 0700, user-only), so only
;; this user can connect.  This is the standard Emacs arbitrary-eval surface;
;; acceptable given the directory permissions.  Negligible runtime cost.
(require 'server)

(unless (server-running-p)
  (server-start))

(provide 'config/services/server)

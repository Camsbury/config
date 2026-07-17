;; -*- lexical-binding: t; -*-
;;; Provider usage ----------------------------------------------------------
;;
;; Fire-and-forget peek at Claude Code and Codex subscription usage.  The
;; `scripts/provider-usage.bb' babashka script reads ECA's OAuth cache, hits
;; each provider's usage endpoint, and (with `--notify') emits one dunst
;; notification per provider.  We run it asynchronously with a discarded
;; buffer so nothing pops up in Emacs; the desktop notifications carry the
;; result.

(require 'prelude)

(defconst ck/eca-provider-usage-script
  (expand-file-name "~/projects/Camsbury/config/scripts/provider-usage.bb")
  "Path to the babashka provider-usage script.")

(defun ck/eca-provider-usage ()
  "Fetch Claude and Codex subscription usage as dunst notifications.
Runs `provider-usage.bb --provider all --notify' asynchronously; the
script sends one desktop notification per provider, so nothing appears in
Emacs itself."
  (interactive)
  (message "Fetching provider usage...")
  (start-process "eca-provider-usage" nil
                 ck/eca-provider-usage-script
                 "--provider" "all" "--notify"))

(provide 'config/services/eca/usage)

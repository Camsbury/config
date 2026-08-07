;; -*- lexical-binding: t; -*-
;;; O(1) pending-approval check ----------------------------------------------
;;
;; ECA's per-redisplay pending-approval scan walks the chat buffer with
;; `text-property-search-forward' from `point-min'.  With nothing pending (the
;; common case) it finds no match and scans all the way to `point-max'.  The
;; mode line and, worse, the tab line call it on every redisplay -- the tab
;; line once per chat in the session -- so a handful of long transcripts turn
;; each repaint into hundreds of kilobytes of property scanning.  Under EXWM
;; that pins a core and stalls the whole desktop (profiled: 84% redisplay,
;; with this leaf dominating the Lisp share and growing with the transcript).
;;
;; The pending marker is a text property stored in the buffer text, so its
;; presence cannot change without the buffer text changing.  That makes
;; `buffer-chars-modified-tick' an exact cache key: memoize the scan on it and
;; the cached answer can never be stale.  Idle chats (stable tick) collapse to
;; O(1); only the one actively streaming buffer rescans, and only itself.
;;
;; The raw full-buffer scan lives behind the adapter
;; (`ck/eca-upstream-buffer-has-pending-approval-p'); this file only memoizes
;; it and self-registers as the adapter's pending-approval check at the bottom
;; (the adapter owns the underlying `:override').

(require 'prelude)
(require 'config/services/eca/upstream)

(defvar-local ck/eca-chat--pending-cache nil
  "Memo cons (CHARS-MODIFIED-TICK . RESULT) for the pending-approval scan.")

(defun ck/eca-chat--has-pending-approvals-p ()
  "Return non-nil if the current chat buffer has a pending approval.
Registered as the adapter's pending-approval check; memoizes the adapter's
full-buffer text-property scan on `buffer-chars-modified-tick', so redisplay
stops re-scanning idle transcripts on every frame."
  (let ((tick (buffer-chars-modified-tick)))
    (if (eql (car ck/eca-chat--pending-cache) tick)
        (cdr ck/eca-chat--pending-cache)
      (let ((result (ck/eca-upstream-buffer-has-pending-approval-p)))
        (setq ck/eca-chat--pending-cache (cons tick result))
        result))))

;; Self-register the memoized check at load time through the adapter.
(ck/eca-upstream-set-pending-approvals-check #'ck/eca-chat--has-pending-approvals-p)

(provide 'config/services/eca/pending)

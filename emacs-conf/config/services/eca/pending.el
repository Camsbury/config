;; -*- lexical-binding: t; -*-
;;; O(1) pending-approval check ----------------------------------------------
;;
;; `eca-chat--has-pending-approvals-p' walks the chat buffer with
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
;; Wired as an `:override' advice in the aggregator's `use-package eca' body,
;; alongside the other eca advices.

(require 'prelude)

(defvar-local ck/eca-chat--pending-cache nil
  "Memo cons (CHARS-MODIFIED-TICK . RESULT) for the pending-approval scan.")

(defun ck/eca-chat--has-pending-approvals-p ()
  "Return non-nil if the current chat buffer has a pending approval.
Drop-in `:override' for `eca-chat--has-pending-approvals-p' that
memoizes its full-buffer text-property scan on
`buffer-chars-modified-tick', so redisplay stops re-scanning idle
transcripts on every frame."
  (let ((tick (buffer-chars-modified-tick)))
    (if (eql (car ck/eca-chat--pending-cache) tick)
        (cdr ck/eca-chat--pending-cache)
      (let ((result (save-excursion
                      (goto-char (point-min))
                      (and (text-property-search-forward
                            'eca-tool-call-pending-approval-accept t t)
                           t))))
        (setq ck/eca-chat--pending-cache (cons tick result))
        result))))

(provide 'config/services/eca/pending)

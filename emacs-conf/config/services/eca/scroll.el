;; -*- lexical-binding: t; -*-
;;; Stream-follow scrolling --------------------------------------------------
;;
;; ECA's stream-follow scroll runs on every streaming update: when the prompt
;; separator is still visible (you are near the bottom) it yanks point to
;; `point-max' and recenters so the view follows new output.  It already
;; suppresses itself once you have scrolled far enough up that the prompt
;; leaves the window, but not while the prompt is still on screen -- so
;; clicking up into the transcript to read or select mid-stream leaves point
;; near the bottom, and the next chunk snaps the cursor back to the prompt.
;;
;; Gate the follower on point actually being in the prompt (text-entry) field
;; through the adapter's prompt-follow extension point: when point is up in the
;; transcript the follow is skipped entirely, so reading mid-stream leaves both
;; cursor and view alone; typing in the prompt still follows the stream exactly
;; as before.  The `ck/eca-upstream-set-prompt-follow-predicate' registration at
;; the bottom of this file installs the gate (the adapter owns the underlying
;; `:before-while').

(require 'prelude)
(require 'config/services/eca/upstream)

(defun ck/eca-chat--follow-only-in-prompt (&rest _)
  "Return non-nil only when point sits in the prompt (text-entry) field.
Registered as the adapter's prompt-follow predicate so the stream-following
scroll and point-move fire only while you are typing in the prompt, never
while you read or scroll the transcript as a response streams."
  (ck/eca-upstream-point-at-prompt-field-p))

;; Self-register the gate at load time.  Satellites load before the deferred
;; `eca' package, so the adapter installs its `:before-while' on the (not yet
;; defined) upstream follower; the advice applies once eca defines it.
(ck/eca-upstream-set-prompt-follow-predicate #'ck/eca-chat--follow-only-in-prompt)

(provide 'config/services/eca/scroll)

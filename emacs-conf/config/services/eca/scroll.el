;; -*- lexical-binding: t; -*-
;;; Stream-follow scrolling --------------------------------------------------
;;
;; ECA's `eca-chat--ensure-prompt-visible' runs on every streaming update: when
;; the prompt separator is still visible (you are near the bottom) it yanks
;; point to `point-max' and recenters so the view follows new output.  It
;; already suppresses itself once you have scrolled far enough up that the
;; prompt leaves the window, but not while the prompt is still on screen -- so
;; clicking up into the transcript to read or select mid-stream leaves point
;; near the bottom, and the next chunk snaps the cursor back to the prompt.
;;
;; Gate the follower on point actually being in the prompt (text-entry) field.
;; `:before-while' skips the original entirely when point is up in the
;; transcript, so reading mid-stream leaves both cursor and view alone; typing
;; in the prompt still follows the stream exactly as before.

(require 'prelude)

(declare-functions "eca-chat" eca-chat--point-at-prompt-field-p)

(defun ck/eca-chat--follow-only-in-prompt (&rest _)
  "Return non-nil only when point sits in the prompt (text-entry) field.
Used as `:before-while' advice on `eca-chat--ensure-prompt-visible' so the
stream-following scroll and point-move fire only while you are typing in the
prompt, never while you read or scroll the transcript as a response streams."
  (eca-chat--point-at-prompt-field-p))

(provide 'config/services/eca/scroll)

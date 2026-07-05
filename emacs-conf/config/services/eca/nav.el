;; -*- lexical-binding: t; -*-
;;; Jump / rotation navigation ----------------------------------------------
;;
;; Jump to the chat that wants you, from anywhere (bound globally via the
;; leader hydra and an EXWM chord, not just from inside a chat).  The design
;; leans on two ECA facts:
;;
;;   - A session's chats are tab-line tabs sharing ONE window; only the
;;     selected tab is that window's buffer, but a background tab can still
;;     need attention (its `eca-chat--pending-question' / pending-approval
;;     state is buffer-local and lives whether or not the tab is visible).
;;   - ECA never pins a session to an EXWM workspace; a session's location is
;;     simply wherever its one window currently sits.
;;
;; So we locate by SESSION, not by the target buffer: if the session's window
;; exists on any frame, switch to that EXWM workspace and toggle its tab to
;; the target (reusing `eca-chat--switch-to-buffer' plus this file's
;; `ck/eca-display-reuse-same-workspace-window' display action, which swaps
;; the tab in place).  If the session has no window anywhere, the same call
;; falls through `display-buffer-alist' to a fresh left pane in the current
;; workspace.  We reuse ECA's own `eca-chat--needs-attention-p' predicate and
;; delegate the `last-chat-buffer' bookkeeping to `eca-chat--switch-to-buffer'
;; (so we never `setf' a struct slot -- avoiding the native-comp setf-expander
;; trap that would bake a call to a nonexistent setter into the cached .eln).

(require 'prelude)
(require 'cl-lib)

(declare-functions "eca-chat"
  eca-chat--needs-attention-p
  eca-chat--switch-to-buffer)
(declare-functions "eca-util"
  eca-vals
  eca-info
  eca--session-id
  eca--session-chats)
(declare-functions "exwm-workspace" exwm-workspace-switch)
(declare-vars eca--sessions eca-chat--chat-loading exwm-workspace--list)

(defun ck/eca--sessions-ordered ()
  "Return all ECA sessions ordered by creation id (stable across calls)."
  (when (boundp 'eca--sessions)
    (sort (copy-sequence (eca-vals eca--sessions))
          (lambda (a b) (< (eca--session-id a) (eca--session-id b))))))

(defun ck/eca--session-chats (session)
  "Return SESSION's chat buffers in tab order (oldest-first)."
  (reverse (eca-vals (eca--session-chats session))))

(defun ck/eca--entries ()
  "Return a flat list of (SESSION . BUFFER) for every live chat.
Ordered by session id, then tab order, matching the tab-line so a
rotation walks chats the same way the eye does."
  (cl-loop for session in (ck/eca--sessions-ordered)
           append (cl-loop for buf in (ck/eca--session-chats session)
                           when (buffer-live-p buf)
                           collect (cons session buf))))

(defun ck/eca--idle-p (buffer)
  "Non-nil when chat BUFFER is idle: live, not loading, not needing attention.
These are the chats you can immediately send a new message to."
  (and (buffer-live-p buffer)
       (with-current-buffer buffer
         (and (derived-mode-p 'eca-chat-mode)
              (not eca-chat--chat-loading)
              (not (eca-chat--needs-attention-p buffer))))))

(defun ck/eca--rotate (pred &optional backward)
  "Return the next (SESSION . BUFFER) whose buffer satisfies PRED.
Anchored at the current buffer and wrapping around, so repeated calls
advance through every match; searches backward when BACKWARD is non-nil.
Returns nil when nothing matches."
  (let* ((entries (ck/eca--entries))
         (entries (if backward (reverse entries) entries)))
    (when entries
      (let* ((cur (current-buffer))
             (pos (cl-position cur entries :key #'cdr))
             ;; Start the search *after* the current chat (wrapping) so a call
             ;; advances rather than re-selecting where we already are.
             (ordered (if pos
                          (append (nthcdr (1+ pos) entries)
                                  (cl-subseq entries 0 (1+ pos)))
                        entries)))
        (seq-find (lambda (e) (funcall pred (cdr e))) ordered)))))

(defun ck/eca--session-window (session)
  "Return a live window on ANY frame showing one of SESSION's chats, or nil.
Because a session's tabs share one window, this finds that window
regardless of which tab is currently the visible one."
  (seq-some (lambda (buf) (get-buffer-window buf t))
            (ck/eca--session-chats session)))

(defun ck/eca--exwm-goto-window (win)
  "Switch to WIN's EXWM workspace (when it is one) and select WIN.
Falls back to plain frame focus for non-workspace frames (e.g. a
floating child frame), and no-ops the switch when WIN is already on the
selected frame."
  (let ((frame (window-frame win)))
    (unless (eq frame (selected-frame))
      (if (and (boundp 'exwm-workspace--list)
               (memq frame exwm-workspace--list)
               (fboundp 'exwm-workspace-switch))
          (exwm-workspace-switch frame)
        (select-frame-set-input-focus frame)))
    (when (window-live-p win)
      (select-window win))))

(defun ck/eca--reveal (session buffer)
  "Reveal chat BUFFER of SESSION and put focus on it.
If SESSION already has a window somewhere, hop to that EXWM workspace
first, then let `eca-chat--switch-to-buffer' (via `display-buffer-alist')
toggle the tab in place; otherwise it opens a fresh pane in the current
workspace."
  (when-let* ((win (ck/eca--session-window session)))
    (ck/eca--exwm-goto-window win))
  (eca-chat--switch-to-buffer buffer session)
  (when-let* ((win (get-buffer-window buffer t)))
    (select-window win)))

(defun ck/eca--jump (pred backward none-msg)
  "Rotate to the next chat matching PRED (BACKWARD-aware) and reveal it.
Show NONE-MSG when nothing matches.  Loads eca lazily so the command
works before any session buffer is current."
  (require 'eca-chat)
  (if-let* ((entry (ck/eca--rotate pred backward)))
      (ck/eca--reveal (car entry) (cdr entry))
    (eca-info none-msg)))

;;;###autoload
(defun ck/eca-jump-to-attention ()
  "Jump to the next ECA chat waiting on you, cycling across all projects.
A chat waits when it has a pending tool-call approval or an unanswered
question.  Lands in the chat's own EXWM workspace when it is already
open there, otherwise opens it as a pane in the current workspace."
  (interactive)
  (ck/eca--jump #'eca-chat--needs-attention-p nil
                "No ECA chat needs attention"))

;;;###autoload
(defun ck/eca-jump-to-attention-back ()
  "Like `ck/eca-jump-to-attention' but rotating in the opposite direction."
  (interactive)
  (ck/eca--jump #'eca-chat--needs-attention-p t
                "No ECA chat needs attention"))

;;;###autoload
(defun ck/eca-jump-to-idle ()
  "Jump to the next idle ECA chat (open, not loading, not waiting on you)."
  (interactive)
  (ck/eca--jump #'ck/eca--idle-p nil "No idle ECA chat"))

;;;###autoload
(defun ck/eca-jump-next ()
  "Jump to the next ECA chat in rotation, whatever its state."
  (interactive)
  (ck/eca--jump (lambda (_buf) t) nil "No ECA chats"))

;;;###autoload
(defun ck/eca-jump-prev ()
  "Jump to the previous ECA chat in rotation, whatever its state."
  (interactive)
  (ck/eca--jump (lambda (_buf) t) t "No ECA chats"))

(provide 'config/services/eca/nav)

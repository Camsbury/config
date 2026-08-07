;; -*- lexical-binding: t; -*-
;;; ECA chat tab management + closed-buffer sweeping -------------------------

(require 'prelude)
(require 'cl-lib)
(require 'config/services/eca/upstream)

(declare-functions "eca-util"
  eca-assert-session-running)

;;; Tab management -----------------------------------------------------------
;;
;; Two closing flavors for the chat tab-line: close just the tab (buffer),
;; or close it and delete the chat server-side.  Cycling left/right is
;; stock `tab-line' -- ECA's tabs carry `buffer' entries, which
;; `tab-line-switch-to-{prev,next}-tab' understands, wrapping at the ends
;; via `tab-line-switch-cycling'.

(defun ck/eca-chat-close-tab ()
  "Close the current chat tab without deleting the chat server-side.
Reuses ECA's own kill-buffer path (sibling-window switch plus session
registry cleanup) but answers its \"delete from server?\" prompt with a
hard no, so the chat can still be resumed later."
  (interactive)
  (unless (derived-mode-p 'eca-chat-mode)
    (user-error "Not in an ECA chat buffer"))
  ;; ECA's `kill-buffer-hook' cleanup only runs when `this-command' looks
  ;; like a kill, and it prompts via `yes-or-no-p' about server-side
  ;; deletion; the chat buffer visits no file, so no other prompt can be
  ;; swallowed by the stub.
  (cl-letf (((symbol-function 'yes-or-no-p) (lambda (&rest _) nil)))
    (let ((this-command 'kill-buffer))
      (kill-buffer (current-buffer)))))

(defun ck/eca-chat-delete-tab ()
  "Close the current chat tab AND delete the chat from the server.
Unlike `eca-chat-delete' this always targets the current buffer's chat,
not the session's last-visited one.  Never prompts."
  (interactive)
  (unless (derived-mode-p 'eca-chat-mode)
    (user-error "Not in an ECA chat buffer"))
  (let ((session (ck/eca-upstream-session))
        (buffer (current-buffer))
        (chat-id (ck/eca-upstream-chat-id)))
    (eca-assert-session-running session)
    (if (not chat-id)
        (ck/eca-chat-close-tab)
      ;; Mark closed so the kill-buffer hook neither prompts nor sends a
      ;; second chat/delete; switch windows to a sibling chat first so the
      ;; chat window keeps showing a chat.
      (ck/eca-upstream-mark-chat-closed)
      (ck/eca-upstream-switch-windows-to-sibling session buffer)
      (unwind-protect
          (ck/eca-upstream-request-sync session
                                        :method "chat/delete"
                                        :params (list :chatId chat-id))
        (when (buffer-live-p buffer)
          (kill-buffer buffer))))))

;;; Closed-buffer sweeping ---------------------------------------------------
;;
;; ECA renames buffers for dead sessions to "<eca ...:closed ...>" instead of
;; killing them, so chat and process-stderr buffers pile up across restarts.
;; Sweep them whenever a session winds down: on the adapter's chat-teardown
;; hook (after a chat/process winds down) and when a chat buffer is killed by
;; hand.

(defvar ck/eca--sweeping nil
  "Reentrancy guard for `ck/eca--sweep-closed-buffers'.
The sweep kills buffers and also runs from `kill-buffer-hook', so without
the guard it would recurse into itself.")

(defun ck/eca--sweep-closed-buffers (&rest _)
  "Kill every closed ECA buffer (chat and process stderr)."
  (unless ck/eca--sweeping
    (let ((ck/eca--sweeping t))
      (dolist (buf (buffer-list))
        (when (and (buffer-live-p buf)
                   (string-match-p "^<eca.*:closed" (buffer-name buf)))
          (kill-buffer buf))))))

(defun ck/eca--sweep-on-chat-kill ()
  "Arrange a closed-buffer sweep when the current chat buffer is killed."
  (add-hook 'kill-buffer-hook #'ck/eca--sweep-closed-buffers nil t))

;; Self-register the sweep on the adapter's chat-teardown hook at load time
;; (the adapter owns the underlying `:after' advice on the wind-down paths).
(ck/eca-upstream-add-chat-teardown-hook #'ck/eca--sweep-closed-buffers)

(provide 'config/services/eca/tabs)

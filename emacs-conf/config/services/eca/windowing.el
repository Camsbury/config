;; -*- lexical-binding: t; -*-
;;; Bounded rendered transcript windows --------------------------------------
;;
;; ECA persists the complete chat server-side and opens only its newest history
;; page into Emacs.  A long-lived live chat defeats that bound: every new turn
;; stays rendered, so the buffer grows without limit and makes each later UI
;; update more expensive.  Under EXWM those costs stall the whole desktop.
;;
;; Once an idle chat crosses `ck/eca-chat-render-max-bytes', reopen the SAME
;; server chat with a bounded history limit.  The server emits `chat/cleared'
;; followed by the newest page, so the local buffer shrinks while the stock
;; "Load older messages" control still reaches the complete history.  Reopens
;; are serialized to avoid several completed agents replaying at once.

(require 'prelude)
(require 'cl-lib)

(declare-functions "eca" eca-session)
(declare-functions "eca-api" eca-api-request-async)
(declare-functions "eca-chat"
  eca-chat--apply-history-meta
  eca-chat--prompt-field-start-point
  eca-chat--protect-non-prompt
  eca-chat--refresh-load-older-control
  eca-chat--set-prompt)
(declare-vars eca-chat--id
              eca-chat--chat-loading
              eca-chat--history-loading
              eca-chat--pending-question)

(defcustom ck/eca-chat-render-max-bytes (* 128 1024)
  "Rendered chat size above which the local transcript is re-windowed.
The complete chat remains on the ECA server.  Re-windowing happens only after
an active turn has finished and never while the chat is selected."
  :type 'integer
  :group 'ck/eca)

(defcustom ck/eca-chat-window-message-limit 24
  "Newest server history items to render after re-windowing a large chat."
  :type '(choice (const :tag "Server default" nil) integer)
  :group 'ck/eca)

(defvar ck/eca-chat--window-queue nil
  "Chat buffers waiting to be re-windowed, oldest request first.")

(defvar ck/eca-chat--window-active nil
  "Chat buffer currently being re-windowed, or nil.")

(defvar ck/eca-chat--window-dispatch-timer nil
  "Zero-delay timer used to dispatch re-window requests outside ECA hooks.")

(defun ck/eca-chat--needs-window-p (buffer)
  "Return non-nil when BUFFER is an idle oversized ECA chat."
  (and (buffer-live-p buffer)
       (with-current-buffer buffer
         (and (derived-mode-p 'eca-chat-mode)
              eca-chat--id
              (not eca-chat--chat-loading)
              (not eca-chat--history-loading)
              (not eca-chat--pending-question)
              (> (buffer-size) ck/eca-chat-render-max-bytes)))))

(defun ck/eca-chat--safe-to-window-p (buffer)
  "Return non-nil when BUFFER can be rebuilt without disrupting the user."
  (and (ck/eca-chat--needs-window-p buffer)
       (not (eq buffer (window-buffer (selected-window))))))

(defun ck/eca-chat--maybe-window (&rest _)
  "Queue the current chat when its rendered transcript exceeds the limit."
  (let ((buffer (current-buffer)))
    (when (and (ck/eca-chat--needs-window-p buffer)
               (not (eq buffer ck/eca-chat--window-active))
               (not (memq buffer ck/eca-chat--window-queue)))
      (setq ck/eca-chat--window-queue
            (nconc ck/eca-chat--window-queue (list buffer))))))

(defun ck/eca-chat--schedule-window-dispatch (&rest _)
  "Schedule one serialized transcript re-window outside the current hook."
  (when (and ck/eca-chat--window-queue
             (not (timerp ck/eca-chat--window-dispatch-timer)))
    (setq ck/eca-chat--window-dispatch-timer
          (run-at-time
           0 nil
           (lambda ()
             (setq ck/eca-chat--window-dispatch-timer nil)
             (ck/eca-chat--dispatch-window-queue))))))

(defun ck/eca-chat-window-if-needed (&rest _)
  "Bound the current ECA transcript after a completed turn, when necessary."
  (ck/eca-chat--maybe-window)
  (ck/eca-chat--schedule-window-dispatch))

(defun ck/eca-chat--next-window-buffer ()
  "Remove and return the first safe chat from the re-window queue."
  (setq ck/eca-chat--window-queue
        (cl-delete-if-not #'ck/eca-chat--needs-window-p
                          ck/eca-chat--window-queue))
  (when-let* ((buffer (seq-find #'ck/eca-chat--safe-to-window-p
                                ck/eca-chat--window-queue)))
    (setq ck/eca-chat--window-queue
          (delq buffer ck/eca-chat--window-queue))
    buffer))

(defun ck/eca-chat--prompt-text ()
  "Return the current prompt text without properties, or nil."
  (when-let* ((start (eca-chat--prompt-field-start-point)))
    (buffer-substring-no-properties start (point-max))))

(defun ck/eca-chat--finish-window (buffer)
  "Finish BUFFER's serialized re-window and dispatch the next candidate."
  (when (eq ck/eca-chat--window-active buffer)
    (setq ck/eca-chat--window-active nil))
  (ck/eca-chat--schedule-window-dispatch))

(defun ck/eca-chat--dispatch-window-queue ()
  "Reopen one queued chat at the newest bounded server-history page."
  (unless ck/eca-chat--window-active
    (when-let* ((buffer (ck/eca-chat--next-window-buffer)))
      (setq ck/eca-chat--window-active buffer)
      (with-current-buffer buffer
        (let ((session (eca-session))
              (chat-id eca-chat--id)
              (prompt (ck/eca-chat--prompt-text))
              (old-size (buffer-size)))
          (eca-api-request-async
           session
           :method "chat/open"
           :params (append (list :chatId chat-id)
                           (when ck/eca-chat-window-message-limit
                             (list :limit ck/eca-chat-window-message-limit)))
           :success-callback
           (lambda (res)
             (when (buffer-live-p buffer)
               (with-current-buffer buffer
                 (if (not (plist-get res :found?))
                     (message "eca: could not re-window chat %s" chat-id)
                   (eca-chat--apply-history-meta (plist-get res :meta))
                   (eca-chat--refresh-load-older-control)
                   (eca-chat--protect-non-prompt)
                   (when (and prompt (not (string-empty-p prompt)))
                     (eca-chat--set-prompt prompt))
                   (message "eca: transcript window %dKB -> %dKB"
                            (/ old-size 1024) (/ (buffer-size) 1024)))))
             (ck/eca-chat--finish-window buffer))
           :error-callback
           (lambda (err)
             (message "eca: transcript re-window failed: %s" err)
             (ck/eca-chat--finish-window buffer))))))))

(provide 'config/services/eca/windowing)

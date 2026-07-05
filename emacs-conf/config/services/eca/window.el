;; -*- lexical-binding: t; -*-
;;; Window placement --------------------------------------------------------
;;
;; Scope chat window reuse to the ECA workspace (the bracketed session name in
;; the buffer name).  Chats from a workspace already on screen toggle into
;; that one window; a different workspace's chat gets its own window instead
;; of hijacking one already showing another session.

(require 'prelude)

(defun ck/eca-chat--workspace-tag (buffer-or-name)
  "Return the \"[workspace]\" tag of an eca chat BUFFER-OR-NAME, or nil.
The tag is the bracketed ECA-session name in the buffer name, e.g.
\"[config]\" from \"<eca-chat[config]:2:7>\"."
  (let ((name (if (bufferp buffer-or-name) (buffer-name buffer-or-name)
                buffer-or-name)))
    (when (and name (string-match "\\`<eca-chat\\(\\[[^]]*\\]\\)" name))
      (match-string 1 name))))

(defun ck/eca-display-reuse-same-workspace-window (buffer alist)
  "`display-buffer' action: reuse a window showing BUFFER's ECA workspace.
Reuses a window on the selected frame already showing an `eca-chat-mode'
buffer whose workspace tag matches BUFFER's, so chats from the same ECA
session toggle in place while a different session gets its own window.
Returns the reused window, or nil to fall through to the next action."
  (when-let* ((tag (ck/eca-chat--workspace-tag buffer)))
    (when-let* ((win (catch 'found
                       (dolist (w (window-list (selected-frame) 'no-mini))
                         (let ((b (window-buffer w)))
                           (when (and (not (eq b buffer))
                                      (eq (buffer-local-value 'major-mode b)
                                          'eca-chat-mode)
                                      (equal (ck/eca-chat--workspace-tag b) tag))
                             (throw 'found w)))))))
      (window--display-buffer buffer win 'reuse alist)
      win)))

(provide 'config/services/eca/window)

;; -*- lexical-binding: t; -*-
;;; Prompt compose buffer ----------------------------------------------------
;;
;; Editing the prompt in place is annoying: RET sends, and any evil edit risks
;; an accidental submit.  Borrowing the `string-edit-at-point' idea, pop the
;; current prompt text into a dedicated buffer where evil motions work freely
;; and RET is just a newline, then commit it back (optionally sending).  Only
;; the plain text round-trips; add `@'-contexts in the chat buffer itself.

(require 'prelude)

(declare-functions "eca-chat"
  eca-chat--prompt-content
  eca-chat--set-prompt
  eca-chat--send-prompt)
(declare-functions "eca-util"
  eca-session)
(declare-vars eca-chat--id)
(declare-functions "markdown-mode" gfm-mode)
(declare-functions "evil-states" evil-normal-state)
(declare-functions "config/modes/prettify-mode" margin-cap-mode)

(defvar-local ck/eca-compose--source-buffer nil
  "The `eca-chat-mode' buffer whose prompt this compose buffer edits.")

(defvar-local ck/eca-compose--chat-id nil
  "The `eca-chat--id' of the chat this compose buffer was spawned from.
Chat tabs are separate buffers (the tab-line lists the session's chat
buffers), each carrying its own stable buffer-local `eca-chat--id'.  We
pin the compose to that id so a commit lands on the originating chat even
after the user toggles the shared chat window to another tab.")

(defun ck/eca-compose--buffer-name (chat-buffer)
  "Return the name of the compose buffer dedicated to CHAT-BUFFER.
Per-chat rather than one shared `*eca-compose*': deriving the name from
the source chat's buffer name gives each chat its own compose buffer, so
opening compose from a second chat never repoints an existing one at the
wrong chat."
  (format "*eca-compose %s*" (buffer-name chat-buffer)))

(defcustom ck/eca-compose-display-direction 'below
  "Direction in which the compose buffer splits off the chat window.
The split is confined to the chat window so it never touches the rest of
the tiling.  `below'/`above' stack them (compose under/over the chat);
`right'/`left' give a side-by-side split."
  :type '(choice (const right) (const left) (const below) (const above))
  :group 'ck/eca)

(defvar ck/eca-compose-mode-map (make-sparse-keymap)
  "Keymap for `ck/eca-compose-mode'.
`C-c C-c' toggles back to the chat (fill prompt, no send), `C-c C-s'
sends, `C-c C-k' aborts.")

(define-minor-mode ck/eca-compose-mode
  "Minor mode for the ECA prompt compose buffer."
  :lighter " eca-compose"
  :keymap ck/eca-compose-mode-map)

(defun ck/eca-chat-edit-prompt ()
  "Edit the current ECA chat prompt in a dedicated compose buffer.
Lifts the prompt text into a separate `gfm-mode' buffer where evil
motions work and RET is a plain newline, so there is no accidental send.
Commit with `ck/eca-compose-finish' (fill back only) or
`ck/eca-compose-send' (fill back and send); drop it with
`ck/eca-compose-abort'.  Only plain text round-trips; add `@'-contexts in
the chat buffer."
  (interactive)
  (unless (derived-mode-p 'eca-chat-mode)
    (user-error "Not in an ECA chat buffer"))
  (let* ((src (current-buffer))
         (chat-id eca-chat--id)
         (win (selected-window))
         (text (or (eca-chat--prompt-content) ""))
         (buf (get-buffer-create (ck/eca-compose--buffer-name src))))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer))
      (if (fboundp 'gfm-mode) (gfm-mode) (text-mode))
      (ck/eca-compose-mode 1)
      ;; Match the parent chat's centered reading column.  The compose
      ;; window is the chat band's one top/bottom pane (see
      ;; `ck/eca-compose-display-direction'), so cap its text area to
      ;; `prettify-width' exactly as the chat does: `margin-cap-mode'
      ;; centers the column when the band is full-width and hugs left when
      ;; tiled, tracking layout via the same global window hooks.
      (when (fboundp 'margin-cap-mode) (margin-cap-mode 1))
      (setq-local ck/eca-compose--source-buffer src)
      (setq-local ck/eca-compose--chat-id chat-id)
      (insert text)
      (goto-char (point-max))
      (when (bound-and-true-p evil-local-mode)
        (evil-normal-state)))
    ;; Split the chat window itself in the chosen direction, so the compose
    ;; window lives inside the chat's footprint and leaves the surrounding
    ;; tiling untouched (a plain `pop-to-buffer' would split an arbitrary
    ;; window).
    (pop-to-buffer buf
                   `((display-buffer-in-direction)
                     (direction . ,ck/eca-compose-display-direction)
                     (window . ,win)
                     ;; Give the compose window a usable share of the chat
                     ;; window rather than the tiny default split.  Only the
                     ;; entry matching the split axis is honored: `window-height'
                     ;; for below/above, `window-width' for left/right.
                     (window-height . 0.4)
                     (window-width . 0.5)
                     ;; Dedicated so killing the compose buffer on
                     ;; finish/abort deletes this window and the chat window
                     ;; reclaims the space, instead of leaving a stray split.
                     (dedicated . t)))))

(defun ck/eca-compose--text ()
  "Return the trimmed contents of the compose buffer."
  (string-trim (buffer-substring-no-properties (point-min) (point-max))))

(defun ck/eca-compose--commit (send)
  "Push the composed text into the source chat prompt; SEND it when non-nil.
Kills the compose buffer and selects the source chat window afterward."
  (unless ck/eca-compose--source-buffer
    (user-error "Not an ECA compose buffer"))
  (let ((src ck/eca-compose--source-buffer)
        (chat-id ck/eca-compose--chat-id)
        (text (ck/eca-compose--text))
        (compose (current-buffer)))
    (unless (buffer-live-p src)
      (user-error "Source ECA chat buffer is gone"))
    ;; Pin to the chat this compose was spawned from.  The source buffer is
    ;; a specific chat tab, and its `eca-chat--id' is stable for that tab's
    ;; life, so a changed id means the buffer was recycled for a different
    ;; chat; refuse rather than silently send to the wrong one.
    (when (and chat-id
               (not (equal chat-id (buffer-local-value 'eca-chat--id src))))
      (user-error "Source ECA chat changed; aborting to avoid wrong target"))
    (when (and send (string-empty-p text))
      (user-error "Refusing to send an empty prompt"))
    (with-current-buffer src
      (if send
          (eca-chat--send-prompt (eca-session) text)
        (eca-chat--set-prompt text)))
    (when (buffer-live-p compose)
      (kill-buffer compose))
    (when-let* ((win (get-buffer-window src t)))
      (select-window win))))

(defun ck/eca-compose-finish ()
  "Write the composed text back into the source chat prompt without sending."
  (interactive)
  (ck/eca-compose--commit nil))

(defun ck/eca-compose-send ()
  "Write the composed text back into the source chat prompt and send it."
  (interactive)
  (ck/eca-compose--commit t))

(defun ck/eca-compose-abort ()
  "Discard the compose buffer, leaving the chat prompt untouched."
  (interactive)
  (let ((src ck/eca-compose--source-buffer)
        (compose (current-buffer)))
    (when (buffer-live-p compose)
      (kill-buffer compose))
    (when-let* ((win (and (buffer-live-p src) (get-buffer-window src t))))
      (select-window win))))

(defun ck/eca-toggle-compose ()
  "Toggle between the chat prompt and its compose buffer.
In an `eca-chat-mode' buffer this opens the compose buffer; in the
compose buffer it fills the text back into the prompt (without sending).
Bound to `C-c C-c' in both, so one chord flips the edit location either
way."
  (interactive)
  (cond
   ((bound-and-true-p ck/eca-compose-mode) (ck/eca-compose-finish))
   ((derived-mode-p 'eca-chat-mode) (ck/eca-chat-edit-prompt))
   (t (user-error "Not in an ECA chat or compose buffer"))))

(define-key ck/eca-compose-mode-map (kbd "C-c C-c") #'ck/eca-toggle-compose)
(define-key ck/eca-compose-mode-map (kbd "C-c C-s") #'ck/eca-compose-send)
(define-key ck/eca-compose-mode-map (kbd "C-c C-k") #'ck/eca-compose-abort)

(provide 'config/services/eca/compose)

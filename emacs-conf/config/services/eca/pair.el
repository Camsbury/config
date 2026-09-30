;; -*- lexical-binding: t; -*-
;;; cam-pair launcher --------------------------------------------------------
;;
;; `M-x ck/eca-pair-open' puts the owner in front of a cam-pair session: the
;; actor chat in the selected window, the critic chat in a band to its right,
;; both on this workspace root's ECA session, each opened with the
;; `/cam-pair:enter' command.  It hides the chat creation, session start,
;; agent selection, and window placement that upstream would otherwise do its
;; own way, and names no eca internal itself: every crossing goes through the
;; ECA upstream adapter.  Re-running the command is the recovery path for a
;; closed chat buffer: it reuses whichever pair chat still exists and creates
;; the other.

(require 'prelude)
(require 'config/services/eca/upstream)

(declare-functions "projectile" projectile-project-root)

(defconst ck/eca-pair-actor-agent "pair-actor"
  "Agent name of the actor chat, as cam-pair's eca.json defines it.")

(defconst ck/eca-pair-critic-agent "pair-critic"
  "Agent name of the critic chat, as cam-pair's eca.json defines it.")

(defconst ck/eca-pair-enter-command "/cam-pair:enter"
  "The opening prompt each pair chat is entered with.
Both roles send the same command; the agent detects its role from the
tools it can see.")

(defconst ck/eca-pair-starting-message
  "ECA session is starting; run again when it is ready"
  "What the launch says when the session is still initializing.
`eca-start-session' answers a starting session with a note of its own
and never runs the ready callback, so without this the command would
look like it did nothing.")

(defconst ck/eca-pair-current-file ".eca/pair/current"
  "Workspace-relative file naming the open pair session.
The referee writes it when it opens a session and removes it at close,
so it is what tells a launch from a resume.")

;;; Workspace and session state ----------------------------------------------

(defun ck/eca-pair--workspace-root ()
  "Return the current workspace root as a directory name, or nil.
Nil when this buffer is in no project, which is the one case the command
refuses: there is no root for the referee's session state to live under."
  (when-let* ((root (projectile-project-root)))
    (file-name-as-directory (expand-file-name root))))

(defun ck/eca-pair--open-session-slug (root)
  "Return the slug of ROOT's open pair session, or nil when none is open."
  (let ((file (expand-file-name ck/eca-pair-current-file root)))
    (when (file-readable-p file)
      (let ((slug (string-trim (with-temp-buffer
                                 (insert-file-contents file)
                                 (buffer-string)))))
        (unless (string-empty-p slug) slug)))))

(defun ck/eca-pair--announcement (root)
  "Return the line saying whether a launch in ROOT is new or a resume.
Read before the chats run: the referee opens a session on the critic's
first tool call, so a moment later this file would say `resume' about
the session this very launch started."
  (if-let* ((slug (ck/eca-pair--open-session-slug root)))
      (format "cam-pair: resume of session %s" slug)
    "cam-pair: new session"))

;;; The two chats -------------------------------------------------------------

(defun ck/eca-pair--chat-for-agent (session agent)
  "Return SESSION's live chat buffer whose selected agent is AGENT, or nil."
  (seq-find (lambda (buffer)
              (and (buffer-live-p buffer)
                   (equal (ck/eca-upstream-chat-agent buffer) agent)))
            (ck/eca-upstream-session-chats session)))

(defun ck/eca-pair--claim-chat (session agent &optional adopt)
  "Make a chat of SESSION carry AGENT and return it.
ADOPT is a chat this launch opened that nothing owns yet; taking it
over is what keeps an upstream-opened chat from becoming a stray third
one.  Without one, a chat is created inside `save-window-excursion',
because creating a chat also opens it."
  (let ((buffer (if (buffer-live-p adopt)
                    adopt
                  (save-window-excursion
                    (ck/eca-upstream-new-chat session)))))
    (ck/eca-upstream-chat-set-agent session agent buffer)
    buffer))

(defun ck/eca-pair--adoptable-chats (session known)
  "Return SESSION's chats that this launch opened, oldest first.
KNOWN is the chat list read before the start, so a chat missing from it
is one `eca-chat-open' made on the way in.  A chat with an agent
already selected belongs to somebody; only the agentless ones are free
to become pair chats."
  (seq-filter (lambda (buffer)
                (and (buffer-live-p buffer)
                     (not (memq buffer known))
                     (null (ck/eca-upstream-chat-agent buffer))))
              (ck/eca-upstream-session-chats session)))

(defun ck/eca-pair--reopen-a-pair-chat (session)
  "Name one of SESSION's pair chats as the chat a start reopens.
`eca-chat-open' creates a chat only when the session's last one is dead,
so a launch made after that buffer was killed reopens a pair chat
instead of adding a third.  Recording the buffer also shows it, hence
the excursion."
  (when-let* ((chat (or (ck/eca-pair--chat-for-agent
                         session ck/eca-pair-actor-agent)
                        (ck/eca-pair--chat-for-agent
                         session ck/eca-pair-critic-agent))))
    (save-window-excursion
      (ck/eca-upstream-switch-to-buffer chat session))))

;;; Windows ------------------------------------------------------------------

(defun ck/eca-pair--usable-window-p (window)
  "Non-nil when WINDOW can take an arbitrary buffer.
A dedicated window, a side window, and the minibuffer all refuse one.
`display-buffer-same-window' then answers nil and `display-buffer'
walks on to `display-buffer-alist', where the ECA entry this launcher
exists to bypass picks the window instead."
  (and (window-live-p window)
       (not (window-dedicated-p window))
       (not (window-parameter window 'window-side))
       (not (window-minibuffer-p window))))

(defun ck/eca-pair--actor-window (origin)
  "Return the window the actor chat belongs in, preferring ORIGIN.
Falls back to any other window that can take a buffer, and then to a
new band split off the frame's main window, so a launch from a
dedicated or side window still shows the actor."
  (or (and (ck/eca-pair--usable-window-p origin) origin)
      (seq-find #'ck/eca-pair--usable-window-p (window-list nil 'never))
      (ignore-errors (split-window (window-main-window) nil 'right))))

(defun ck/eca-pair--reclaim-chat-windows (session keep)
  "Delete every window showing a chat of SESSION, except KEEP.
The start opened a chat window before this launcher ran, on a started
session and on a cold start alike.  The launcher owns the layout, so it
takes those windows back and then places the two pair chats itself."
  (dolist (buffer (ck/eca-upstream-session-chats session))
    (when (buffer-live-p buffer)
      (dolist (window (get-buffer-window-list buffer nil nil))
        (unless (eq window keep)
          (ignore-errors (delete-window window)))))))

(defun ck/eca-pair--place-chats (actor critic origin)
  "Show ACTOR in ORIGIN and CRITIC in a band to its right.
ORIGIN is the window the command was run from, captured before any
upstream call, because starting a session selects a chat window of its
own.  `ck/display-buffer-right-band' (config/navigation.el) is named as
data and never called here, so this file needs no load-order
relationship with that module: `display-buffer' resolves the symbol
when the command runs, well after boot."
  (let ((window (ck/eca-pair--actor-window origin)))
    (if (window-live-p window)
        (with-selected-window window
          (let ((display-buffer-overriding-action
                 '(display-buffer-same-window)))
            (display-buffer actor)))
      (let ((display-buffer-overriding-action
             '(ck/display-buffer-right-band)))
        (display-buffer actor))))
  (with-selected-window (or (get-buffer-window actor) (selected-window))
    (let ((display-buffer-overriding-action '(ck/display-buffer-right-band)))
      (display-buffer critic))))

(defun ck/eca-pair--enter (buffer)
  "Send the opening command in BUFFER when it is idle.
Returns non-nil when it was sent.  A chat that is running, or waiting on
an approval or an answer, is waiting on the owner, and a prompt pushed
into it would jump that queue."
  (when (eq (ck/eca-upstream-chat-status buffer) 'idle)
    (with-current-buffer buffer
      (ck/eca-upstream-set-prompt ck/eca-pair-enter-command)
      ;; Point must sit past the prompt field first: the RET dispatcher has
      ;; point-dependent branches (button, expandable block, link) ahead of
      ;; the send, exactly as eca/compose.el handles it.
      (goto-char (point-max))
      (ck/eca-upstream-send-return))
    t))

(defun ck/eca-pair--open-chats (session announcement origin known)
  "Open, place, and enter SESSION's pair chats, then say ANNOUNCEMENT.
ORIGIN is the window the command was run from and KNOWN the chats the
session had before the start, so a chat the start opened is adopted
into a pair role rather than left behind.  Returns a plist of
`:actor', `:critic', and `:entered', the buffers that were prompted,
critic first."
  (let ((default-agent (ck/eca-upstream-session-default-agent session))
        (spare (ck/eca-pair--adoptable-chats session known))
        critic actor entered)
    (setq critic (ck/eca-pair--chat-for-agent
                  session ck/eca-pair-critic-agent)
          actor (ck/eca-pair--chat-for-agent
                 session ck/eca-pair-actor-agent))
    (unwind-protect
        (progn
          (unless critic
            (setq critic (ck/eca-pair--claim-chat
                          session ck/eca-pair-critic-agent (pop spare))))
          (unless actor
            (setq actor (ck/eca-pair--claim-chat
                         session ck/eca-pair-actor-agent (pop spare)))))
      (ck/eca-upstream-set-session-default-agent session default-agent))
    (ck/eca-pair--reclaim-chat-windows session origin)
    (ck/eca-pair--place-chats actor critic origin)
    ;; The critic enters first: its first tool call is what opens the session
    ;; the actor then joins.
    (when (ck/eca-pair--enter critic) (push critic entered))
    (when (ck/eca-pair--enter actor) (push actor entered))
    (when-let* ((window (get-buffer-window actor)))
      (select-window window))
    (with-current-buffer actor
      (when-let* ((start (ck/eca-upstream-prompt-field-start-point)))
        (goto-char start)))
    (message "%s" announcement)
    (list :actor actor :critic critic :entered (nreverse entered))))

;;;###autoload
(defun ck/eca-pair-open ()
  "Open this workspace's cam-pair chats, actor and critic, in one command.
Finds or starts the ECA session for the workspace root, reuses whichever
pair chat already exists there, creates the other, places them, and
enters each idle one with `/cam-pair:enter'.  Point ends in the actor's
prompt.  Says whether this launch opens a new session or resumes the one
`.eca/pair/current' names.  A session that is still starting is left
alone, with a message: its server cannot answer yet."
  (interactive)
  (if-let* ((root (ck/eca-pair--workspace-root)))
      (let ((session (ck/eca-upstream-session-for-root root)))
        (if (ck/eca-upstream-session-starting-p session)
            (progn (message "%s" ck/eca-pair-starting-message) nil)
          (let ((announcement (ck/eca-pair--announcement root))
                (origin (selected-window))
                (known (and session
                            (ck/eca-upstream-session-chats session))))
            (when session (ck/eca-pair--reopen-a-pair-chat session))
            (ck/eca-upstream-start-session
             session root
             (lambda (session)
               (ck/eca-pair--open-chats
                session announcement origin known))))))
    (message "cam-pair: no workspace root here; no chats opened")
    nil))

(provide 'config/services/eca/pair)

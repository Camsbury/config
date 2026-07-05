;; -*- lexical-binding: t; -*-
;;; Chat-scoped config isolation ---------------------------------------------
;;
;; Make "change agent/model on one tab" affect only that tab.  Two upstream
;; defects conspire to leak a per-chat change into every other tab; the fix
;; has three cooperating pieces: register a fresh chat with the server up
;; front (so the server can scope updates to it), re-attach the dropped
;; chat-id on the wire, and shadow the global config fallbacks.

(require 'prelude)
(require 'cl-lib)

(declare-functions "eca-util"
  eca-session
  eca-assert-session-running)
(declare-functions "eca-chat"
  eca-chat--set-chat-loading
  eca-chat--model
  eca-chat--agent
  eca-chat--new-chat
  eca-chat--get-last-buffer)
(declare-functions "eca-api"
  eca-api-request-async)
(declare-vars eca-chat--id
              eca-chat--closed
              eca-chat--last-request-id
              eca-chat--last-known-model
              eca-chat--last-known-agent
              eca-chat--last-known-variant
              eca-chat--last-known-trust)

;;; Server-identified new chats ---------------------------------------------
;;
;; The ECA server only creates a chat record (`[:chats id]') on a chat's FIRST
;; `chat/prompt'.  A tab that has not yet been prompted is unknown server-side,
;; and the agent/model-change handlers then drop its chat-id and broadcast the
;; change session-wide -- so switching agent or model on a fresh tab clobbers
;; every other open chat.  We sidestep that by registering the chat up front:
;; fire one benign no-LLM slash command (`/costs' routes through the server's
;; command handler, which seeds the chat record and finishes idle without ever
;; calling a model).  Its short output stays on screen; since command output is
;; display-only (never persisted to the chat's messages), it neither pollutes
;; the LLM context nor needs clearing.

(defcustom ck/eca-chat-register-command "/costs"
  "Slash command used to register a new chat with the ECA server.
Must be a command the server answers WITHOUT calling an LLM -- it only needs
to make the server seed the chat record.  `/costs' is the lightest such
command: it reads a few usage counters, prints a short system message, and
finishes idle.  Command output is display-only (the server never adds it to
the chat's message list), so it does not leak into the LLM conversation and
is safe to leave on screen."
  :type 'string
  :group 'ck/eca)

(defun ck/eca--register-current-chat (session)
  "Register the current chat buffer with SESSION's server via a benign command.
Sends `ck/eca-chat-register-command' as a real `chat/prompt' carrying the
buffer's eager chat-id, which makes the server create its `[:chats id]'
record.  The command's short output is left on screen.  No-op without a
chat-id or on an already-closed buffer."
  (when (and eca-chat--id (not eca-chat--closed))
    ;; Flip loading so the turn renders like any normal command turn (spinner,
    ;; then a clean finish that fontifies the output and runs the finished-hook).
    (eca-chat--set-chat-loading session t)
    (eca-api-request-async
     session
     :method "chat/prompt"
     :params (list :message ck/eca-chat-register-command
                   :request-id (cl-incf eca-chat--last-request-id)
                   :chatId eca-chat--id
                   :model (eca-chat--model)
                   :agent (eca-chat--agent)
                   :contexts [])
     ;; The id is already buffer-local; the response carries nothing we need.
     :success-callback #'ignore)))

(defun ck/eca-chat-new-registered ()
  "Create a new ECA chat that is registered with the server immediately.
Unlike `eca-chat-new', the fresh tab is known server-side before its first
real prompt, so changing its agent or model is scoped to this tab alone and
no longer clobbers the other open chats."
  (interactive)
  (let ((session (eca-session)))
    (eca-assert-session-running session)
    (eca-chat--new-chat session)
    (when-let* ((buf (eca-chat--get-last-buffer session)))
      (with-current-buffer buf
        (ck/eca--register-current-chat session)))))

;;; Config-update scoping ----------------------------------------------------
;;
;; Two upstream defects conspire to make "change agent/model on one tab"
;; leak into every other tab (verified against eca server 141.0 +
;; eca-emacs 20260629.1508); both are worked around here:
;;
;; 1. Wire mismatch (the big one): the server scopes a per-chat
;;    `config/updated' by putting `chatId' at the TOP LEVEL of the payload
;;    ({"chat": {...}, "chatId": "..."}, see the server's
;;    `notify-fields-changed-only!'), but `eca-config-updated' extracts only
;;    the inner `:chat' plist and passes that to `eca-chat-config-updated',
;;    dropping the id.  The chat handler therefore never sees a `chatId',
;;    always takes its legacy session-wide branch, and stomps every tab's
;;    buffer-local model/agent/variant.  Fix:
;;    `ck/eca--config-updated-attach-chat-id' re-attaches the top-level id
;;    onto the `:chat' plist before dispatch, so the upstream scoped branch
;;    (eca-emacs#231) finally runs.
;;
;; 2. Global fallback writes: `eca-chat--apply-per-chat-config' and the
;;    interactive selectors (`eca-chat--set-agent',
;;    `eca-chat-select-model', `eca-chat-select-variant') write the GLOBAL
;;    `eca-chat--last-known-{model,agent,variant,trust}' even for
;;    buffer-scoped changes.  Tabs whose buffer-local selection is nil
;;    display AND send those globals, so they silently follow.  Fix: shadow
;;    the globals (dynamic let) around scoped paths, so buffer-local writes
;;    land and global writes evaporate on exit.  Globals then change only
;;    on genuine session-wide broadcasts (post-initialize defaults), which
;;    also means a NEW tab inherits the session default rather than the
;;    last per-tab pick; that is the intended isolation semantics.
;;
;; Server-side scoping additionally requires the chat to EXIST in the
;; server db (an unknown id falls back to a session-wide broadcast by
;; design), hence the /costs registration above.  All three pieces are
;; needed.

(defun ck/eca--config-updated-attach-chat-id (fn session config)
  "Around-advice for `eca-config-updated' (FN, SESSION, CONFIG).
Re-attach the top-level `:chatId' onto the inner `:chat' plist, which is
where `eca-chat-config-updated' expects it; without this the scoped
branch never runs and per-chat updates broadcast to every tab."
  (let ((chat-id (plist-get config :chatId))
        (chat (plist-get config :chat)))
    (funcall fn session
             (if (and chat-id chat (not (plist-get chat :chatId)))
                 (plist-put (copy-sequence config) :chat
                            (append (list :chatId chat-id) chat))
               config))))

(defun ck/eca--shadow-config-globals (fn &rest args)
  "Around-advice shadowing the global last-known config fallbacks.
Runs FN with ARGS while the four `eca-chat--last-known-*' globals are
dynamically rebound, so a buffer-scoped selection cannot leak to other
tabs through the global fallback display path."
  (let ((eca-chat--last-known-model eca-chat--last-known-model)
        (eca-chat--last-known-agent eca-chat--last-known-agent)
        (eca-chat--last-known-variant eca-chat--last-known-variant)
        (eca-chat--last-known-trust eca-chat--last-known-trust))
    (apply fn args)))

(defun ck/eca--config-updated-guard-globals (fn session chat-config)
  "Around-advice for `eca-chat-config-updated' (FN, SESSION, CHAT-CONFIG).
Confine chat-scoped payloads (those carrying `chatId') to buffer-local
state by shadowing the global last-known fallbacks for the duration."
  (if (plist-get chat-config :chatId)
      (let ((eca-chat--last-known-model eca-chat--last-known-model)
            (eca-chat--last-known-agent eca-chat--last-known-agent)
            (eca-chat--last-known-variant eca-chat--last-known-variant)
            (eca-chat--last-known-trust eca-chat--last-known-trust))
        (funcall fn session chat-config))
    (funcall fn session chat-config)))

(provide 'config/services/eca/isolation)

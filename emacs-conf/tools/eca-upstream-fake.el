;;; eca-upstream-fake.el --- in-memory fake of the ECA upstream adapter -*- lexical-binding: t; -*-
;;
;; A second, upstream-free implementation of the `ck/eca-upstream-' interface
;; defined in config/services/eca/upstream.el, for tests.  Load it in place of
;; the real adapter and every accessor reads in-memory state instead of the
;; live `eca-emacs' package, so a test can drive the satellites without a
;; running ECA server, session, or chat.
;;
;; Usage in a test: set chat state with `ck/eca-upstream-fake-setup-chat',
;; point the session at a value, run the code under test, then read the
;; captured request with `ck/eca-upstream-fake-last-request'.
;;
;; Loading this file DEFINES the same `ck/eca-upstream-' function names the
;; real adapter does; whichever loads last wins, so a test requires this after
;; (or instead of) the real adapter.

(require 'cl-lib)
(require 'text-property-search)

;;; In-memory state ----------------------------------------------------------

(cl-defstruct (ck/eca-upstream-fake-session
               (:constructor ck/eca-upstream-fake--make-session)
               (:copier nil))
  "An in-memory stand-in for one `eca--session'.
Carries only what the adapter interface exposes: the session id, the
workspace root it owns, its chat buffers, the default agent a new chat
inherits, the server status, and the chat a start reopens."
  id root chats default-agent (status 'stopped) last-chat)

(defvar ck/eca-upstream-fake--session 'fake-session
  "Value returned by the fake `ck/eca-upstream-session'.")

(defvar ck/eca-upstream-fake--sessions nil
  "Sessions returned by the fake `ck/eca-upstream-sessions'.")

(defvar ck/eca-upstream-fake--session-counter 0
  "Ids handed to fake sessions, monotonic within a test run.")

(defvar ck/eca-upstream-fake--chat-counter 0
  "Ids handed to fake chat buffers, monotonic within a test run.")

(defvar ck/eca-upstream-fake--requests nil
  "Captured requests, newest first.
Each entry is (KIND SESSION . ARGS) where KIND is `async' or `sync'.")

(defvar ck/eca-upstream-fake--sync-response nil
  "Value the fake `ck/eca-upstream-request-sync' returns.")

;; Per-chat state.  Buffer-local so several fake chat buffers can coexist in
;; one test, mirroring how the real eca-chat buffer-locals behave.
(defvar-local ck/eca-upstream-fake--chat-id nil)
(defvar-local ck/eca-upstream-fake--chat-agent nil)
(defvar-local ck/eca-upstream-fake--chat-status 'idle)
(defvar-local ck/eca-upstream-fake--chat-loading nil)
(defvar-local ck/eca-upstream-fake--history-loading nil)
(defvar-local ck/eca-upstream-fake--pending-questions nil)
(defvar-local ck/eca-upstream-fake--closed nil)
(defvar-local ck/eca-upstream-fake--last-user-message-pos nil)
(defvar-local ck/eca-upstream-fake--prompt-field-start-point nil)
(defvar-local ck/eca-upstream-fake--prompt-area-start-point nil)
(defvar-local ck/eca-upstream-fake--prompt-content "")

;; Extension-point handlers, defined here (before `ck/eca-upstream-fake-reset'
;; clears them) so the fake byte-compiles without forward-reference warnings.
(defvar ck/eca-upstream-fake--chat-teardown-handlers nil)
(defvar ck/eca-upstream-fake--context-category-color-filter nil)
(defvar ck/eca-upstream-fake--context-free-color-filter nil)
(defvar ck/eca-upstream-fake--context-bar-help-filter nil)
(defvar ck/eca-upstream-fake--pending-approvals-check nil)
(defvar ck/eca-upstream-fake--server-version-source nil)
(defvar ck/eca-upstream-fake--prompt-follow-predicate nil)

;;; Test setup / inspection --------------------------------------------------

(cl-defun ck/eca-upstream-fake-setup-chat
    (&key (buffer (current-buffer))
          id agent (status 'idle)
          chat-loading history-loading pending-questions closed
          last-user-message-pos prompt-field-start-point
          prompt-area-start-point (prompt-content ""))
  "Establish fake chat state in BUFFER from the keyword arguments.
Replaces the `setq-local eca-chat--...' block a test would otherwise
write; each keyword maps to the matching `ck/eca-upstream-' accessor."
  (with-current-buffer buffer
    (setq-local ck/eca-upstream-fake--chat-id id
                ck/eca-upstream-fake--chat-agent agent
                ck/eca-upstream-fake--chat-status status
                ck/eca-upstream-fake--chat-loading chat-loading
                ck/eca-upstream-fake--history-loading history-loading
                ck/eca-upstream-fake--pending-questions pending-questions
                ck/eca-upstream-fake--closed closed
                ck/eca-upstream-fake--last-user-message-pos last-user-message-pos
                ck/eca-upstream-fake--prompt-field-start-point prompt-field-start-point
                ck/eca-upstream-fake--prompt-area-start-point prompt-area-start-point
                ck/eca-upstream-fake--prompt-content prompt-content)))

(defun ck/eca-upstream-fake-set-chat-status (buffer status)
  "Set BUFFER's fake chat STATUS, as `ck/eca-upstream-chat-status' reads it."
  (with-current-buffer buffer
    (setq-local ck/eca-upstream-fake--chat-status status)))

(defun ck/eca-upstream-fake-set-session-status (session status)
  "Set SESSION's server STATUS: `stopped', `starting', or `started'.
Mirrors the `eca--session' status slot that `eca-start-session'
branches on."
  (setf (ck/eca-upstream-fake-session-status session) status))

(defun ck/eca-upstream-fake-set-last-chat (session buffer)
  "Make BUFFER the chat a start of SESSION reopens.
Stands for `eca--session-last-chat-buffer', which is what
`eca-chat-open' tests for liveness before creating a chat."
  (setf (ck/eca-upstream-fake-session-last-chat session) buffer))

(defun ck/eca-upstream-fake-sent-prompts ()
  "Return every prompt sent, oldest first, as (BUFFER . TEXT) pairs."
  (nreverse
   (seq-keep (lambda (entry)
               (when (and (consp entry) (eq (car entry) 'send-return))
                 (cons (nth 1 entry) (nth 2 entry))))
             ck/eca-upstream-fake--requests)))

(defun ck/eca-upstream-fake-reset ()
  "Clear captured requests and reset most session and handler state.
Kills the chat buffers the fake created, so one test's chats cannot be
found by the next one.  It leaves
`ck/eca-upstream-fake--history-calls' and
`ck/eca-upstream-fake--block-at-point' alone, so a test that reads either
must set it itself."
  (dolist (session ck/eca-upstream-fake--sessions)
    (dolist (buffer (ck/eca-upstream-fake-session-chats session))
      (when (buffer-live-p buffer) (kill-buffer buffer))))
  (setq ck/eca-upstream-fake--session-counter 0
        ck/eca-upstream-fake--chat-counter 0)
  (setq ck/eca-upstream-fake--session 'fake-session
        ck/eca-upstream-fake--sessions nil
        ck/eca-upstream-fake--requests nil
        ck/eca-upstream-fake--sync-response nil
        ck/eca-upstream-fake--chat-teardown-handlers nil
        ck/eca-upstream-fake--context-category-color-filter nil
        ck/eca-upstream-fake--context-free-color-filter nil
        ck/eca-upstream-fake--context-bar-help-filter nil
        ck/eca-upstream-fake--pending-approvals-check nil
        ck/eca-upstream-fake--server-version-source nil
        ck/eca-upstream-fake--prompt-follow-predicate nil))

(defun ck/eca-upstream-fake-last-request ()
  "Return the ARGS plist of the most recent captured request, or nil.
ARGS is everything after the session, matching what a test previously
captured from `eca-api-request-async'."
  (cddr (car ck/eca-upstream-fake--requests)))

;;; Session / chat registry --------------------------------------------------

(defun ck/eca-upstream-session ()
  ck/eca-upstream-fake--session)

(defun ck/eca-upstream-sessions ()
  ck/eca-upstream-fake--sessions)

(defun ck/eca-upstream-session-id (session)
  ;; A fake session is the struct above; any other object stands for a
  ;; session with no structure and is its own id.
  (if (ck/eca-upstream-fake-session-p session)
      (ck/eca-upstream-fake-session-id session)
    session))

(defun ck/eca-upstream-session-chats (session)
  (when (ck/eca-upstream-fake-session-p session)
    (ck/eca-upstream-fake-session-chats session)))

(defun ck/eca-upstream-info (format &rest args)
  (apply #'message (concat "ECA :: " format) args))

;;; Session lifecycle --------------------------------------------------------

(defun ck/eca-upstream-session-for-root (root)
  (seq-find (lambda (session)
              (equal (ck/eca-upstream-fake-session-root session) root))
            ck/eca-upstream-fake--sessions))

(defun ck/eca-upstream-start-session (session root on-ready)
  "Mirror `eca-start-session' against in-memory state.
Every branch upstream takes is here, because what the launcher must
survive is what the start does BEFORE ON-READY: a started session runs
`eca-chat-open' and a cold start runs it inside `eca--initialize', so
both open a chat and take a window.  A `starting' session only reports
itself and never calls ON-READY.  The fake server answers at once, so
the cold start is synchronous here while upstream's is asynchronous."
  (let ((session (or session
                     (let ((new (ck/eca-upstream-fake--make-session
                                 :id (cl-incf
                                      ck/eca-upstream-fake--session-counter)
                                 :root root)))
                       (push new ck/eca-upstream-fake--sessions)
                       new))))
    (push (list 'start-session session root)
          ck/eca-upstream-fake--requests)
    (if (eq 'starting (ck/eca-upstream-fake-session-status session))
        (message "eca server is already starting")
      (ck/eca-upstream-fake--chat-open session)
      (setf (ck/eca-upstream-fake-session-status session) 'started)
      (when on-ready (funcall on-ready session)))
    session))

(defun ck/eca-upstream-fake--create-chat (session)
  "Create a fresh chat buffer in SESSION and return it, opening no window."
  (let ((buffer (generate-new-buffer
                 (format "<eca-chat[fake]:%d>"
                         (cl-incf ck/eca-upstream-fake--chat-counter)))))
    (with-current-buffer buffer
      (setq major-mode 'eca-chat-mode)
      (insert "fake chat transcript\n")
      (let ((prompt-start (point-max)))
        (insert "prompt\n")
        (ck/eca-upstream-fake-setup-chat
         :buffer buffer
         :id (format "chat-%d" ck/eca-upstream-fake--chat-counter)
         :prompt-field-start-point prompt-start)))
    (setf (ck/eca-upstream-fake-session-chats session)
          (append (ck/eca-upstream-fake-session-chats session)
                  (list buffer)))
    buffer))

(defun ck/eca-upstream-fake--chat-open (session)
  "Mirror `eca-chat-open' for SESSION.
Creates a chat when the session has no live one, then selects the
window already showing it or opens a new one to the right, which is
what cmacs runs (`eca-chat-window-side' at its default `right', with
`eca-chat-use-side-window' nil, and `eca-chat-focus-on-open' t).  A
caller that must keep its layout has to take that window back."
  (let ((buffer (ck/eca-upstream-fake-session-last-chat session)))
    (unless (buffer-live-p buffer)
      (setq buffer (ck/eca-upstream-fake--create-chat session)))
    (let ((window (or (get-buffer-window buffer)
                      (display-buffer buffer
                                      '((display-buffer-in-direction)
                                        (direction . right))))))
      (when (window-live-p window) (select-window window)))
    (setf (ck/eca-upstream-fake-session-last-chat session) buffer)
    buffer))

(defun ck/eca-upstream-new-chat (session)
  ;; Mirror `eca-chat--new-chat': the new buffer becomes the session's last
  ;; chat and is then opened, which changes the window configuration.  A
  ;; caller that must not disturb the layout has to wrap this in
  ;; `save-window-excursion'.
  (let ((buffer (ck/eca-upstream-fake--create-chat session)))
    (setf (ck/eca-upstream-fake-session-last-chat session) buffer)
    (ck/eca-upstream-fake--chat-open session)
    buffer))

(defun ck/eca-upstream-session-starting-p (session)
  (and (ck/eca-upstream-fake-session-p session)
       (eq 'starting (ck/eca-upstream-fake-session-status session))))

(defun ck/eca-upstream-session-default-agent (session)
  (ck/eca-upstream-fake-session-default-agent session))

(defun ck/eca-upstream-set-session-default-agent (session agent)
  (setf (ck/eca-upstream-fake-session-default-agent session) agent))

;;; Chat buffer state --------------------------------------------------------

(defun ck/eca-upstream--fake-blocal (var &optional buffer)
  (buffer-local-value var (or buffer (current-buffer))))

(defun ck/eca-upstream-chat-id (&optional buffer)
  (ck/eca-upstream--fake-blocal 'ck/eca-upstream-fake--chat-id buffer))

(defun ck/eca-upstream-chat-loading-p (&optional buffer)
  (ck/eca-upstream--fake-blocal 'ck/eca-upstream-fake--chat-loading buffer))

(defun ck/eca-upstream-history-loading-p (&optional buffer)
  (ck/eca-upstream--fake-blocal 'ck/eca-upstream-fake--history-loading buffer))

(defun ck/eca-upstream-pending-questions (&optional buffer)
  (ck/eca-upstream--fake-blocal
   'ck/eca-upstream-fake--pending-questions buffer))

(defun ck/eca-upstream-chat-closed-p (&optional buffer)
  (ck/eca-upstream--fake-blocal 'ck/eca-upstream-fake--closed buffer))

(defun ck/eca-upstream-mark-chat-closed (&optional buffer)
  (with-current-buffer (or buffer (current-buffer))
    (setq-local ck/eca-upstream-fake--closed t)))

(defun ck/eca-upstream-last-user-message-pos (&optional buffer)
  (ck/eca-upstream--fake-blocal 'ck/eca-upstream-fake--last-user-message-pos buffer))

(defun ck/eca-upstream-chat-agent (&optional buffer)
  (ck/eca-upstream--fake-blocal 'ck/eca-upstream-fake--chat-agent buffer))

(defun ck/eca-upstream-chat-set-agent (session agent &optional buffer)
  (with-current-buffer (or buffer (current-buffer))
    (setq-local ck/eca-upstream-fake--chat-agent agent))
  ;; Upstream's `eca-chat--set-agent' also moves the session default.  The
  ;; fake copies that side effect on purpose: without it, a test of the
  ;; launcher's restore would pass on nothing.
  (setf (ck/eca-upstream-fake-session-default-agent session) agent)
  (push (list 'chat-set-agent session agent buffer)
        ck/eca-upstream-fake--requests))

(defun ck/eca-upstream-chat-status (buffer)
  (ck/eca-upstream--fake-blocal 'ck/eca-upstream-fake--chat-status buffer))

;;; Prompt geometry / content ------------------------------------------------

(defun ck/eca-upstream-prompt-field-start-point ()
  ck/eca-upstream-fake--prompt-field-start-point)

(defun ck/eca-upstream-prompt-area-start-point ()
  ck/eca-upstream-fake--prompt-area-start-point)

(defun ck/eca-upstream-prompt-content ()
  ck/eca-upstream-fake--prompt-content)

(defun ck/eca-upstream-set-prompt (text)
  (setq-local ck/eca-upstream-fake--prompt-content text))

(defun ck/eca-upstream-point-at-prompt-field-p ()
  (when-let* ((start ck/eca-upstream-fake--prompt-field-start-point))
    (>= (point) start)))

(defun ck/eca-upstream-prompt-context-field-ov ()
  nil)

(defun ck/eca-upstream-insert (text)
  (insert text))

(defun ck/eca-upstream-send-return ()
  ;; Records the buffer, not the session: what a caller must prove is WHICH
  ;; chat a prompt reached (see `ck/eca-upstream-fake-sent-prompts').
  (push (list 'send-return (current-buffer)
              (ck/eca-upstream-prompt-content))
        ck/eca-upstream-fake--requests))

;;; History replay -----------------------------------------------------------
;;
;; No local transcript to rebuild in a fake; record the calls so a test can
;; assert the replay sequence ran.

(defvar ck/eca-upstream-fake--history-calls nil
  "History-replay calls made, newest first.")

(defun ck/eca-upstream-apply-history-meta (meta)
  (push (list 'apply-history-meta meta) ck/eca-upstream-fake--history-calls))

(defun ck/eca-upstream-refresh-load-older-control ()
  (push (list 'refresh-load-older-control) ck/eca-upstream-fake--history-calls))

(defun ck/eca-upstream-protect-non-prompt ()
  (push (list 'protect-non-prompt) ck/eca-upstream-fake--history-calls))

;;; Server request crossing --------------------------------------------------
;;
;; Capture args and, like the real async request, do NOT invoke callbacks, so
;; a caller's in-flight bookkeeping stays "in flight" for assertions.

(defun ck/eca-upstream-request-async (session &rest args)
  (push (cons 'async (cons session args)) ck/eca-upstream-fake--requests)
  nil)

(defun ck/eca-upstream-request-sync (session &rest args)
  (push (cons 'sync (cons session args)) ck/eca-upstream-fake--requests)
  ck/eca-upstream-fake--sync-response)

;;; Chat navigation / attention ----------------------------------------------

(defun ck/eca-upstream-needs-attention-p (buffer)
  ;; Mirror upstream's guards: only a live chat buffer can need attention.
  (and (buffer-live-p buffer)
       (with-current-buffer buffer
         (and (derived-mode-p 'eca-chat-mode)
              (or (ck/eca-upstream-pending-questions buffer)
                  (ck/eca-upstream-buffer-has-pending-approval-p))
              t))))

(defun ck/eca-upstream-switch-to-buffer (buffer session)
  ;; Upstream also records the buffer as the session's last chat, which is
  ;; what a later `eca-chat-open' reopens instead of creating a chat.
  (when (buffer-live-p buffer)
    (if-let* ((window (get-buffer-window buffer)))
        (select-window window)
      (switch-to-buffer buffer))
    (when (ck/eca-upstream-fake-session-p session)
      (setf (ck/eca-upstream-fake-session-last-chat session) buffer))
    buffer))

(defun ck/eca-upstream-switch-windows-to-sibling (session buffer)
  (push (list 'switch-windows-to-sibling session buffer)
        ck/eca-upstream-fake--requests))

;;; Expandable-block overlays ------------------------------------------------
;;
;; These are plain overlay/text-property operations with no upstream call, so
;; the fake shares the real property names and behaves identically on a buffer
;; a test has decorated with matching overlays.

(defun ck/eca-upstream-block-overlays (&optional beg end)
  (seq-filter (lambda (ov) (overlay-get ov 'eca-chat--expandable-content-id))
              (overlays-in (or beg (point-min)) (or end (point-max)))))

(defun ck/eca-upstream-block-id (ov)
  (overlay-get ov 'eca-chat--expandable-content-id))

(defun ck/eca-upstream-block-open-p (ov)
  (and (overlay-get ov 'eca-chat--expandable-content-toggle) t))

(defun ck/eca-upstream-block-segments (ov)
  (overlay-get ov 'eca-chat--expandable-content-segments))

(defun ck/eca-upstream-block-ov-content (ov)
  (overlay-get ov 'eca-chat--expandable-content-ov-content))

(defvar ck/eca-upstream-fake--block-at-point nil
  "Overlay the fake `ck/eca-upstream-block-at-point' returns.")

(defun ck/eca-upstream-block-at-point ()
  ck/eca-upstream-fake--block-at-point)

(defun ck/eca-upstream-toggle-block (id &rest args)
  (push (cons 'toggle-block (cons id args)) ck/eca-upstream-fake--requests))

;;; Table overlays -----------------------------------------------------------

(defun ck/eca-upstream-table-overlay-p (ov)
  (or (overlay-get ov 'eca-table-action)
      (overlay-get ov 'eca-table-overlay)))

;;; Pending-approval scan ----------------------------------------------------

(defun ck/eca-upstream-buffer-has-pending-approval-p ()
  (save-excursion
    (goto-char (point-min))
    (and (text-property-search-forward
          'eca-tool-call-pending-approval-accept t t)
         t)))

;;; Extension points ---------------------------------------------------------
;;
;; No real `advice-add' (there is no upstream to advise); registration just
;; stores the handler (declared up in the state section), and a matching
;; dispatch function lets a test invoke it exactly as the real dispatcher
;; would.

(defun ck/eca-upstream-add-chat-teardown-hook (fn)
  (add-to-list 'ck/eca-upstream-fake--chat-teardown-handlers fn t))

(defun ck/eca-upstream-set-context-category-color-filter (fn)
  (setq ck/eca-upstream-fake--context-category-color-filter fn))

(defun ck/eca-upstream-set-context-free-color-filter (fn)
  (setq ck/eca-upstream-fake--context-free-color-filter fn))

(defun ck/eca-upstream-set-context-bar-help-filter (fn)
  (setq ck/eca-upstream-fake--context-bar-help-filter fn))

(defun ck/eca-upstream-set-pending-approvals-check (fn)
  (setq ck/eca-upstream-fake--pending-approvals-check fn))

(defun ck/eca-upstream-set-server-version-source (fn)
  (setq ck/eca-upstream-fake--server-version-source fn))

(defun ck/eca-upstream-set-prompt-follow-predicate (fn)
  (setq ck/eca-upstream-fake--prompt-follow-predicate fn))

;; Dispatchers a test drives to exercise a registered handler.
(defun ck/eca-upstream-fake-fire-chat-teardown ()
  "Run every registered chat-teardown handler."
  (dolist (fn ck/eca-upstream-fake--chat-teardown-handlers)
    (funcall fn)))

(defun ck/eca-upstream-fake-apply-category-color-filter (args)
  (if ck/eca-upstream-fake--context-category-color-filter
      (funcall ck/eca-upstream-fake--context-category-color-filter args)
    args))

(defun ck/eca-upstream-fake-apply-free-color-filter (args)
  (if ck/eca-upstream-fake--context-free-color-filter
      (funcall ck/eca-upstream-fake--context-free-color-filter args)
    args))

(defun ck/eca-upstream-fake-apply-bar-help-filter (args)
  (if ck/eca-upstream-fake--context-bar-help-filter
      (funcall ck/eca-upstream-fake--context-bar-help-filter args)
    args))

(defun ck/eca-upstream-fake-run-pending-approvals-check (&rest args)
  (when ck/eca-upstream-fake--pending-approvals-check
    (apply ck/eca-upstream-fake--pending-approvals-check args)))

(defun ck/eca-upstream-fake-run-server-version-source (&rest args)
  (when ck/eca-upstream-fake--server-version-source
    (apply ck/eca-upstream-fake--server-version-source args)))

(defun ck/eca-upstream-fake-run-prompt-follow-predicate (&rest args)
  (if ck/eca-upstream-fake--prompt-follow-predicate
      (apply ck/eca-upstream-fake--prompt-follow-predicate args)
    t))

(defun ck/eca-upstream-wiring-report ()
  "Return a short note that this is the in-memory fake adapter."
  (interactive)
  "fake ECA upstream adapter (in-memory; no advice installed)")

(provide 'eca-upstream-fake)

;;; eca-upstream-fake.el ends here

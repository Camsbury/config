;;; eca-upstream-fake.el --- in-memory fake of the ECA upstream adapter -*- lexical-binding: t; -*-
;;
;; A second, upstream-free implementation of the `ck/eca-upstream-' interface
;; defined in config/services/eca/upstream.el, for tests.  Load it in place of
;; the real adapter and every accessor reads in-memory state instead of the
;; live `eca-emacs' package, so a test can drive the satellites without a
;; running ECA server, session, or chat.
;;
;; It exists to replace the ad-hoc `cl-letf' / `setq-local' fakery that tests
;; grow (see tools/eca-windowing-test.el): set chat state with
;; `ck/eca-upstream-fake-setup-chat', point the session at a value, run the
;; code under test, then read the captured request with
;; `ck/eca-upstream-fake-last-request'.
;;
;; Loading this file DEFINES the same `ck/eca-upstream-' function names the
;; real adapter does; whichever loads last wins, so a test requires this after
;; (or instead of) the real adapter.

(require 'cl-lib)
(require 'text-property-search)

;;; In-memory state ----------------------------------------------------------

(defvar ck/eca-upstream-fake--session 'fake-session
  "Value returned by the fake `ck/eca-upstream-session'.")

(defvar ck/eca-upstream-fake--sessions nil
  "Sessions returned by the fake `ck/eca-upstream-sessions'.")

(defvar ck/eca-upstream-fake--requests nil
  "Captured requests, newest first.
Each entry is (KIND SESSION . ARGS) where KIND is `async' or `sync'.")

(defvar ck/eca-upstream-fake--sync-response nil
  "Value the fake `ck/eca-upstream-request-sync' returns.")

;; Per-chat state.  Buffer-local so several fake chat buffers can coexist in
;; one test, mirroring how the real eca-chat buffer-locals behave.
(defvar-local ck/eca-upstream-fake--chat-id nil)
(defvar-local ck/eca-upstream-fake--chat-loading nil)
(defvar-local ck/eca-upstream-fake--history-loading nil)
(defvar-local ck/eca-upstream-fake--pending-question nil)
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
          id chat-loading history-loading pending-question closed
          last-user-message-pos prompt-field-start-point
          prompt-area-start-point (prompt-content ""))
  "Establish fake chat state in BUFFER from the keyword arguments.
Replaces the `setq-local eca-chat--...' block a test would otherwise
write; each keyword maps to the matching `ck/eca-upstream-' accessor."
  (with-current-buffer buffer
    (setq-local ck/eca-upstream-fake--chat-id id
                ck/eca-upstream-fake--chat-loading chat-loading
                ck/eca-upstream-fake--history-loading history-loading
                ck/eca-upstream-fake--pending-question pending-question
                ck/eca-upstream-fake--closed closed
                ck/eca-upstream-fake--last-user-message-pos last-user-message-pos
                ck/eca-upstream-fake--prompt-field-start-point prompt-field-start-point
                ck/eca-upstream-fake--prompt-area-start-point prompt-area-start-point
                ck/eca-upstream-fake--prompt-content prompt-content)))

(defun ck/eca-upstream-fake-reset ()
  "Clear captured requests and reset session/handler state to defaults."
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
  ;; Fake sessions are (id . chats) conses, or any object with a stored id.
  (if (consp session) (car session) session))

(defun ck/eca-upstream-session-chats (session)
  (when (consp session) (cdr session)))

(defun ck/eca-upstream-info (format &rest args)
  (apply #'message (concat "ECA :: " format) args))

;;; Chat buffer state --------------------------------------------------------

(defun ck/eca-upstream--fake-blocal (var &optional buffer)
  (buffer-local-value var (or buffer (current-buffer))))

(defun ck/eca-upstream-chat-id (&optional buffer)
  (ck/eca-upstream--fake-blocal 'ck/eca-upstream-fake--chat-id buffer))

(defun ck/eca-upstream-chat-loading-p (&optional buffer)
  (ck/eca-upstream--fake-blocal 'ck/eca-upstream-fake--chat-loading buffer))

(defun ck/eca-upstream-history-loading-p (&optional buffer)
  (ck/eca-upstream--fake-blocal 'ck/eca-upstream-fake--history-loading buffer))

(defun ck/eca-upstream-pending-question (&optional buffer)
  (ck/eca-upstream--fake-blocal 'ck/eca-upstream-fake--pending-question buffer))

(defun ck/eca-upstream-chat-closed-p (&optional buffer)
  (ck/eca-upstream--fake-blocal 'ck/eca-upstream-fake--closed buffer))

(defun ck/eca-upstream-mark-chat-closed (&optional buffer)
  (with-current-buffer (or buffer (current-buffer))
    (setq-local ck/eca-upstream-fake--closed t)))

(defun ck/eca-upstream-last-user-message-pos (&optional buffer)
  (ck/eca-upstream--fake-blocal 'ck/eca-upstream-fake--last-user-message-pos buffer))

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
  (push (list 'send-return ck/eca-upstream-fake--session
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
  (or (ck/eca-upstream-pending-question buffer)
      (with-current-buffer buffer
        (ck/eca-upstream-buffer-has-pending-approval-p))))

(defun ck/eca-upstream-switch-to-buffer (buffer _session)
  (when (buffer-live-p buffer)
    (switch-to-buffer buffer)))

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

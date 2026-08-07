;; -*- lexical-binding: t; -*-
;;; ECA Upstream Adapter -----------------------------------------------------
;;
;; One boundary between our ECA chat customizations and the version-fragile
;; internals of the upstream `eca-emacs' package.  Every satellite touch of an
;; eca private (a `eca-chat--' function, a `eca--session' struct slot, a
;; `eca-vals' / `eca-info' helper, an internal text or overlay property) and
;; every advice we install on an upstream function goes THROUGH here, so a
;; breaking rename upstream lands in exactly one file instead of a dozen.
;;
;; Loaded FIRST in the eca aggregator's require list, before the satellites, so
;; every `ck/eca-upstream-' name is defined by the time a satellite calls it.
;;
;; Two kinds of surface:
;;
;;   Accessors     intention-revealing readers/writers grouped by concept
;;                 (session lookup, chat state, prompt geometry, history
;;                 replay, request crossing, block overlays, table overlays,
;;                 pending-approval scan).  Each wraps one or more upstream
;;                 privates but names the CONCEPT, not the private.
;;
;;   Extension     for every upstream function we advise, the adapter owns the
;;   points        `advice-add' and exposes a named registration function.  A
;;                 satellite registers its handler; the adapter installs a
;;                 single dispatch advice lazily (on first registration) and
;;                 routes the upstream call to the registered handler(s).  All
;;                 four combinator shapes are covered: `:after' (teardown
;;                 hook), `:filter-args' (context-bar color/emoji strippers),
;;                 `:override' (pending-approval check, server-version source)
;;                 and `:before-while' (prompt-follow predicate).
;;
;; A parallel in-memory implementation of this same interface lives in
;; tools/eca-upstream-fake.el for tests; tools/eca-upstream-guard.sh asserts
;; every upstream symbol wrapped below still exists in the installed package.

(require 'prelude)

;; Forward declarations so byte-compiling this file (before the deferred eca
;; package loads) stays warning-free.  These are the ONLY upstream names this
;; adapter is allowed to touch; adding one here is the deliberate act of
;; widening the boundary.
(declare-functions "eca-util"
  eca-session
  eca-info
  eca-vals
  eca--session-id
  eca--session-chats)
(declare-functions "eca-api"
  eca-api-request-async
  eca-api-request-sync)
(declare-functions "eca-chat"
  eca-chat--apply-history-meta
  eca-chat--prompt-field-start-point
  eca-chat--prompt-area-start-point
  eca-chat--prompt-content
  eca-chat--set-prompt
  eca-chat--point-at-prompt-field-p
  eca-chat--prompt-context-field-ov
  eca-chat--insert
  eca-chat--key-pressed-return
  eca-chat--protect-non-prompt
  eca-chat--refresh-load-older-control
  eca-chat--needs-attention-p
  eca-chat--switch-to-buffer
  eca-chat--switch-windows-to-sibling
  eca-chat--expandable-content-at-point-dwim
  eca-chat--expandable-content-toggle)
(declare-vars eca--sessions
              eca-chat--id
              eca-chat--chat-loading
              eca-chat--history-loading
              eca-chat--pending-question
              eca-chat--closed
              eca-chat--last-user-message-pos)

;;; Internal properties ------------------------------------------------------
;;
;; The version-fragile text/overlay property names, named once.  Everything
;; below reads them through these constants so a rename is a one-line change.

(defconst ck/eca-upstream-block-id-prop 'eca-chat--expandable-content-id
  "Overlay property carrying an expandable block's id.")
(defconst ck/eca-upstream-block-open-prop 'eca-chat--expandable-content-toggle
  "Overlay property that is non-nil while an expandable block is expanded.")
(defconst ck/eca-upstream-block-segments-prop 'eca-chat--expandable-content-segments
  "Overlay property holding an expandable block's stored segment list.")
(defconst ck/eca-upstream-block-ov-content-prop 'eca-chat--expandable-content-ov-content
  "Overlay property holding an expandable block's stored overlay content.")
(defconst ck/eca-upstream-table-action-prop 'eca-table-action
  "Overlay property marking an eca table action overlay.")
(defconst ck/eca-upstream-table-overlay-prop 'eca-table-overlay
  "Overlay property marking an eca table body overlay.")
(defconst ck/eca-upstream-pending-approval-prop 'eca-tool-call-pending-approval-accept
  "Text property marking an accept-able pending tool-call approval.")

;;; Session / chat registry --------------------------------------------------

(defun ck/eca-upstream-session ()
  "Return the ECA session for the current context."
  (eca-session))

(defun ck/eca-upstream-sessions ()
  "Return every live ECA session, unordered, or nil before any exists."
  (when (boundp 'eca--sessions)
    (eca-vals eca--sessions)))

(defun ck/eca-upstream-session-id (session)
  "Return SESSION's creation id (stable, monotonic per session)."
  (eca--session-id session))

(defun ck/eca-upstream-session-chats (session)
  "Return SESSION's chat buffers as a list (callers impose tab order)."
  (eca-vals (eca--session-chats session)))

(defun ck/eca-upstream-info (format &rest args)
  "Show an ECA info message built from FORMAT and ARGS."
  (apply #'eca-info format args))

;;; Chat buffer state --------------------------------------------------------
;;
;; Each reads a buffer-local eca-chat slot; BUFFER defaults to the current
;; buffer so callers walking the buffer list can pass an explicit target.

(defun ck/eca-upstream--blocal (var &optional buffer)
  "Return buffer-local VAR in BUFFER (default current buffer)."
  (buffer-local-value var (or buffer (current-buffer))))

(defun ck/eca-upstream-chat-id (&optional buffer)
  "Return BUFFER's chat id, or nil."
  (ck/eca-upstream--blocal 'eca-chat--id buffer))

(defun ck/eca-upstream-chat-loading-p (&optional buffer)
  "Non-nil when BUFFER's chat is mid-turn (loading a response)."
  (ck/eca-upstream--blocal 'eca-chat--chat-loading buffer))

(defun ck/eca-upstream-history-loading-p (&optional buffer)
  "Non-nil when BUFFER is loading older history."
  (ck/eca-upstream--blocal 'eca-chat--history-loading buffer))

(defun ck/eca-upstream-pending-question (&optional buffer)
  "Return BUFFER's unanswered question, or nil."
  (ck/eca-upstream--blocal 'eca-chat--pending-question buffer))

(defun ck/eca-upstream-chat-closed-p (&optional buffer)
  "Non-nil when BUFFER's chat is marked closed."
  (ck/eca-upstream--blocal 'eca-chat--closed buffer))

(defun ck/eca-upstream-mark-chat-closed (&optional buffer)
  "Mark BUFFER's chat closed so the kill-buffer path neither prompts nor resends."
  (with-current-buffer (or buffer (current-buffer))
    (setq-local eca-chat--closed t)))

(defun ck/eca-upstream-last-user-message-pos (&optional buffer)
  "Return the position of BUFFER's last user message, or nil."
  (ck/eca-upstream--blocal 'eca-chat--last-user-message-pos buffer))

;;; Prompt geometry / content ------------------------------------------------

(defun ck/eca-upstream-prompt-field-start-point ()
  "Return the point where the editable prompt field begins, or nil."
  (eca-chat--prompt-field-start-point))

(defun ck/eca-upstream-prompt-area-start-point ()
  "Return the point where the whole prompt area (field plus context) begins."
  (eca-chat--prompt-area-start-point))

(defun ck/eca-upstream-prompt-content ()
  "Return the current prompt text."
  (eca-chat--prompt-content))

(defun ck/eca-upstream-set-prompt (text)
  "Replace the prompt field contents with TEXT."
  (eca-chat--set-prompt text))

(defun ck/eca-upstream-point-at-prompt-field-p ()
  "Non-nil when point sits in the editable prompt field."
  (eca-chat--point-at-prompt-field-p))

(defun ck/eca-upstream-prompt-context-field-ov ()
  "Return the prompt context-field overlay at point, or nil."
  (eca-chat--prompt-context-field-ov))

(defun ck/eca-upstream-insert (text)
  "Insert TEXT into the prompt field via eca's own insertion path."
  (eca-chat--insert text))

(defun ck/eca-upstream-send-return ()
  "Send the prompt exactly as pressing RET in the chat would."
  (eca-chat--key-pressed-return))

;;; History replay -----------------------------------------------------------

(defun ck/eca-upstream-apply-history-meta (meta)
  "Rebuild the local transcript from server history META."
  (eca-chat--apply-history-meta meta))

(defun ck/eca-upstream-refresh-load-older-control ()
  "Refresh the \"Load older messages\" control after a history change."
  (eca-chat--refresh-load-older-control))

(defun ck/eca-upstream-protect-non-prompt ()
  "Re-protect the read-only non-prompt region after a rebuild."
  (eca-chat--protect-non-prompt))

;;; Server request crossing --------------------------------------------------

(defun ck/eca-upstream-request-async (session &rest args)
  "Send an async JSON-RPC request on SESSION with ARGS."
  (apply #'eca-api-request-async session args))

(defun ck/eca-upstream-request-sync (session &rest args)
  "Send a synchronous JSON-RPC request on SESSION with ARGS and return the reply."
  (apply #'eca-api-request-sync session args))

;;; Chat navigation / attention ----------------------------------------------

(defun ck/eca-upstream-needs-attention-p (buffer)
  "Non-nil when chat BUFFER wants the user (pending approval or question)."
  (eca-chat--needs-attention-p buffer))

(defun ck/eca-upstream-switch-to-buffer (buffer session)
  "Reveal chat BUFFER of SESSION, updating eca's last-chat bookkeeping."
  (eca-chat--switch-to-buffer buffer session))

(defun ck/eca-upstream-switch-windows-to-sibling (session buffer)
  "Move SESSION's windows off BUFFER onto a sibling chat before it is killed."
  (eca-chat--switch-windows-to-sibling session buffer))

;;; Expandable-block overlays ------------------------------------------------

(defun ck/eca-upstream-block-overlays (&optional beg end)
  "Return every expandable-block label overlay between BEG and END.
BEG/END default to the whole buffer."
  (seq-filter (lambda (ov) (overlay-get ov ck/eca-upstream-block-id-prop))
              (overlays-in (or beg (point-min)) (or end (point-max)))))

(defun ck/eca-upstream-block-id (ov)
  "Return the block id stored on overlay OV."
  (overlay-get ov ck/eca-upstream-block-id-prop))

(defun ck/eca-upstream-block-open-p (ov)
  "Non-nil when block overlay OV is currently expanded."
  (and (overlay-get ov ck/eca-upstream-block-open-prop) t))

(defun ck/eca-upstream-block-segments (ov)
  "Return the stored segment list on block overlay OV."
  (overlay-get ov ck/eca-upstream-block-segments-prop))

(defun ck/eca-upstream-block-ov-content (ov)
  "Return the stored overlay content on block overlay OV."
  (overlay-get ov ck/eca-upstream-block-ov-content-prop))

(defun ck/eca-upstream-block-at-point ()
  "Return the expandable-block overlay at or around point, or nil."
  (eca-chat--expandable-content-at-point-dwim))

(defun ck/eca-upstream-toggle-block (id &rest args)
  "Toggle the expandable block named ID.
ARGS pass through eca's optional close/no-recenter flags."
  (apply #'eca-chat--expandable-content-toggle id args))

;;; Table overlays -----------------------------------------------------------

(defun ck/eca-upstream-table-overlay-p (ov)
  "Non-nil when OV is one of eca's table overlays (action or body)."
  (or (overlay-get ov ck/eca-upstream-table-action-prop)
      (overlay-get ov ck/eca-upstream-table-overlay-prop)))

;;; Pending-approval scan ----------------------------------------------------

(defun ck/eca-upstream-buffer-has-pending-approval-p ()
  "Non-nil when the current buffer carries an accept-able pending approval.
A raw full-buffer text-property scan; callers may memoize it (see the
pending satellite)."
  (save-excursion
    (goto-char (point-min))
    (and (text-property-search-forward
          ck/eca-upstream-pending-approval-prop t t)
         t)))

;;; Extension points ---------------------------------------------------------
;;
;; The adapter owns every `advice-add' on an upstream function.  A satellite
;; registers a handler through the named function below; the adapter installs
;; a single dispatch advice on first registration and routes the upstream call
;; to the handler.  Lazy install keeps upstream untouched until something opts
;; in, and means an `:override' / `:before-while' dispatcher only ever runs
;; with a handler present.

(defvar ck/eca-upstream--installed (make-hash-table :test 'eq)
  "Upstream symbols this adapter has already installed dispatch advice on.")

(defun ck/eca-upstream--install-once (symbol how dispatcher)
  "Install HOW advice DISPATCHER on upstream SYMBOL exactly once."
  (unless (gethash symbol ck/eca-upstream--installed)
    (advice-add symbol how dispatcher)
    (puthash symbol (list how dispatcher) ck/eca-upstream--installed)))

;;;; :after -- chat teardown hook (serves tabs) ------------------------------

(defvar ck/eca-upstream--chat-teardown-handlers nil
  "Functions run after a chat/process winds down.")

(defun ck/eca-upstream--dispatch-chat-teardown (&rest _)
  "Run every registered chat-teardown handler."
  (dolist (fn ck/eca-upstream--chat-teardown-handlers)
    (funcall fn)))

(defun ck/eca-upstream-add-chat-teardown-hook (fn)
  "Run FN after `eca-process-stop' and after `eca-chat-exit'.
Registers a chat-teardown handler and installs the `:after' dispatch on
both upstream functions the first time it is called."
  (add-to-list 'ck/eca-upstream--chat-teardown-handlers fn t)
  (ck/eca-upstream--install-once
   'eca-process-stop :after #'ck/eca-upstream--dispatch-chat-teardown)
  (ck/eca-upstream--install-once
   'eca-chat-exit :after #'ck/eca-upstream--dispatch-chat-teardown))

;;;; :filter-args -- context category color strip (serves colors) -----------

(defvar ck/eca-upstream--context-category-color-filter nil
  "Handler transforming the args of the context category color resolvers.")

(defun ck/eca-upstream--dispatch-context-category-color-filter (args)
  "Route ARGS through the registered category-color filter, or pass through."
  (if ck/eca-upstream--context-category-color-filter
      (funcall ck/eca-upstream--context-category-color-filter args)
    args))

(defun ck/eca-upstream-set-context-category-color-filter (fn)
  "Filter the args of the context category color/face resolvers through FN.
FN takes and returns an arg list; installed as `:filter-args' on both
`eca-chat--context-category-color' and `...-face-spec'."
  (setq ck/eca-upstream--context-category-color-filter fn)
  (dolist (sym '(eca-chat--context-category-color
                 eca-chat--context-category-face-spec))
    (ck/eca-upstream--install-once
     sym :filter-args
     #'ck/eca-upstream--dispatch-context-category-color-filter)))

;;;; :filter-args -- context free color strip (serves colors) ---------------

(defvar ck/eca-upstream--context-free-color-filter nil
  "Handler transforming the args of the context free-region color resolvers.")

(defun ck/eca-upstream--dispatch-context-free-color-filter (args)
  "Route ARGS through the registered free-color filter, or pass through."
  (if ck/eca-upstream--context-free-color-filter
      (funcall ck/eca-upstream--context-free-color-filter args)
    args))

(defun ck/eca-upstream-set-context-free-color-filter (fn)
  "Filter the args of the context free color/face resolvers through FN.
FN takes and returns an arg list; installed as `:filter-args' on both
`eca-chat--context-free-color' and `...-face-spec'."
  (setq ck/eca-upstream--context-free-color-filter fn)
  (dolist (sym '(eca-chat--context-free-color
                 eca-chat--context-free-face-spec))
    (ck/eca-upstream--install-once
     sym :filter-args
     #'ck/eca-upstream--dispatch-context-free-color-filter)))

;;;; :filter-args -- context bar help emoji strip (serves colors) -----------

(defvar ck/eca-upstream--context-bar-help-filter nil
  "Handler transforming the args of the context-bar hover legend.")

(defun ck/eca-upstream--dispatch-context-bar-help-filter (args)
  "Route ARGS through the registered bar-help filter, or pass through."
  (if ck/eca-upstream--context-bar-help-filter
      (funcall ck/eca-upstream--context-bar-help-filter args)
    args))

(defun ck/eca-upstream-set-context-bar-help-filter (fn)
  "Filter the args of `eca-chat--context-bar-help' through FN.
FN takes and returns an arg list; installed as `:filter-args'."
  (setq ck/eca-upstream--context-bar-help-filter fn)
  (ck/eca-upstream--install-once
   'eca-chat--context-bar-help :filter-args
   #'ck/eca-upstream--dispatch-context-bar-help-filter))

;;;; :override -- pending-approval check (serves pending) --------------------

(defvar ck/eca-upstream--pending-approvals-check nil
  "Handler replacing the per-redisplay pending-approval scan.")

(defun ck/eca-upstream--dispatch-pending-approvals-check (&rest args)
  "Call the registered pending-approval check with ARGS."
  (apply ck/eca-upstream--pending-approvals-check args))

(defun ck/eca-upstream-set-pending-approvals-check (fn)
  "Replace `eca-chat--has-pending-approvals-p' with FN.
Installed as `:override'; FN is the sole implementation once registered."
  (setq ck/eca-upstream--pending-approvals-check fn)
  (ck/eca-upstream--install-once
   'eca-chat--has-pending-approvals-p :override
   #'ck/eca-upstream--dispatch-pending-approvals-check))

;;;; :override -- server version source (serves the aggregator pin) ----------

(defvar ck/eca-upstream--server-version-source nil
  "Handler replacing eca's \"latest server version\" lookup.")

(defun ck/eca-upstream--dispatch-server-version-source (&rest args)
  "Call the registered server-version source with ARGS."
  (apply ck/eca-upstream--server-version-source args))

(defun ck/eca-upstream-set-server-version-source (fn)
  "Replace `eca-process--get-latest-server-version' with FN.
Installed as `:override' so eca never contacts GitHub to decide \"latest\"."
  (setq ck/eca-upstream--server-version-source fn)
  (ck/eca-upstream--install-once
   'eca-process--get-latest-server-version :override
   #'ck/eca-upstream--dispatch-server-version-source))

;;;; :before-while -- prompt-follow predicate (serves scroll) ----------------

(defvar ck/eca-upstream--prompt-follow-predicate nil
  "Predicate gating whether the stream-follow scroll runs.")

(defun ck/eca-upstream--dispatch-prompt-follow-predicate (&rest args)
  "Call the registered prompt-follow predicate with ARGS, defaulting to t."
  (if ck/eca-upstream--prompt-follow-predicate
      (apply ck/eca-upstream--prompt-follow-predicate args)
    t))

(defun ck/eca-upstream-set-prompt-follow-predicate (fn)
  "Gate `eca-chat--ensure-prompt-visible' on FN.
Installed as `:before-while'; when FN returns nil the stream-follow
scroll is skipped for that update."
  (setq ck/eca-upstream--prompt-follow-predicate fn)
  (ck/eca-upstream--install-once
   'eca-chat--ensure-prompt-visible :before-while
   #'ck/eca-upstream--dispatch-prompt-follow-predicate))

;;; Wiring report ------------------------------------------------------------

(defun ck/eca-upstream-wiring-report ()
  "Return (and when interactive, display) what is registered where.
Lists every advised upstream symbol the adapter has installed dispatch
on, plus which handlers are currently registered at each extension point."
  (interactive)
  (let* ((installed (let (acc)
                      (maphash (lambda (sym meta)
                                 (push (format "  %-42s %s" sym (car meta)) acc))
                               ck/eca-upstream--installed)
                      (nreverse acc)))
         (handlers
          (list
           (format "  chat-teardown        : %d handler(s) %S"
                   (length ck/eca-upstream--chat-teardown-handlers)
                   ck/eca-upstream--chat-teardown-handlers)
           (format "  category-color-filter: %S"
                   ck/eca-upstream--context-category-color-filter)
           (format "  free-color-filter    : %S"
                   ck/eca-upstream--context-free-color-filter)
           (format "  bar-help-filter      : %S"
                   ck/eca-upstream--context-bar-help-filter)
           (format "  pending-approvals    : %S"
                   ck/eca-upstream--pending-approvals-check)
           (format "  server-version       : %S"
                   ck/eca-upstream--server-version-source)
           (format "  prompt-follow        : %S"
                   ck/eca-upstream--prompt-follow-predicate)))
         (report (string-join
                  (append '("ECA upstream adapter -- advised symbols:")
                          (or installed '("  (none installed yet)"))
                          '("ECA upstream adapter -- registered handlers:")
                          handlers)
                  "\n")))
    (when (called-interactively-p 'interactive)
      (message "%s" report))
    report))

(provide 'config/services/eca/upstream)

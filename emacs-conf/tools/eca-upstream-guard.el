;;; eca-upstream-guard.el --- fail when an upstream eca symbol we wrap vanishes -*- lexical-binding: t; -*-
;;
;; Batch payload for tools/eca-upstream-guard.sh.  The ECA Upstream Adapter
;; (config/services/eca/upstream.el) is the one boundary between our chat
;; customizations and the version-fragile internals of the installed
;; `eca-emacs' package.  That protection is only real if the adapter's list of
;; wrapped upstream names stays in sync with what the package actually
;; provides.  This guard machine-checks it: every upstream function/variable
;; the adapter reads or advises must still be `fboundp' / `boundp', and every
;; internal text/overlay property it names must still appear in the owning
;; package source.  A FAIL means an upstream rename slipped past us; update the
;; adapter (one file) to match.
;;
;; Run via tools/eca-upstream-guard.sh (resolves the emacs binary +
;; EMACSLOADPATH from the cmacs launcher, exactly like lib-guard.sh).

(require 'find-func)

(defconst ck/eca-upstream-guard--functions
  '(;; accessor targets
    eca-session eca-info eca-vals eca--session-id eca--session-chats
    eca-api-request-async eca-api-request-sync
    eca-chat--apply-history-meta eca-chat--prompt-field-start-point
    eca-chat--prompt-area-start-point eca-chat--prompt-content
    eca-chat--set-prompt eca-chat--point-at-prompt-field-p
    eca-chat--prompt-context-field-ov eca-chat--insert
    eca-chat--key-pressed-return eca-chat--protect-non-prompt
    eca-chat--refresh-load-older-control eca-chat--needs-attention-p
    eca-chat--switch-to-buffer eca-chat--switch-windows-to-sibling
    eca-chat--expandable-content-at-point-dwim
    eca-chat--expandable-content-toggle
    ;; advice targets (extension points)
    eca-process-stop eca-chat-exit
    eca-chat--context-category-color eca-chat--context-category-face-spec
    eca-chat--context-free-color eca-chat--context-free-face-spec
    eca-chat--context-bar-help
    eca-chat--has-pending-approvals-p
    eca-process--get-latest-server-version
    eca-chat--ensure-prompt-visible)
  "Upstream functions the adapter calls or advises; each must stay `fboundp'.")

(defconst ck/eca-upstream-guard--variables
  '(eca--sessions eca-chat--id eca-chat--chat-loading
    eca-chat--history-loading eca-chat--pending-question
    eca-chat--closed eca-chat--last-user-message-pos)
  "Upstream variables the adapter reads; each must stay `boundp'.")

(defconst ck/eca-upstream-guard--properties
  '(("eca-chat--expandable-content-id"      . "eca-chat")
    ("eca-chat--expandable-content-toggle"  . "eca-chat")
    ("eca-chat--expandable-content-segments" . "eca-chat")
    ("eca-chat--expandable-content-ov-content" . "eca-chat")
    ("eca-table-action"                     . "eca-table")
    ("eca-table-overlay"                    . "eca-table")
    ("eca-tool-call-pending-approval-accept" . "eca-chat"))
  "Internal text/overlay property names the adapter uses, and the library
whose source must still mention each (properties are not `fboundp'-checkable).")

(defun ck/eca-upstream-guard--name-in-library-p (name library)
  "Non-nil when NAME appears as text in LIBRARY's source file."
  (let ((file (ignore-errors (find-library-name library))))
    (and file
         (file-readable-p file)
         (with-temp-buffer
           (insert-file-contents file)
           (goto-char (point-min))
           (search-forward name nil t)))))

(let ((failures 0))
  ;; Load the package so its symbols are interned.
  (condition-case err
      (dolist (feat '(eca-util eca-api eca-process eca-chat eca-table eca))
        (require feat))
    (error
     (princ (format "eca-upstream-guard: cannot load eca package: %S\n" err))
     (kill-emacs 2)))

  (dolist (sym ck/eca-upstream-guard--functions)
    (let ((ok (fboundp sym)))
      (princ (format "%-46s fn      %s\n" sym (if ok "OK" "MISSING")))
      (unless ok (setq failures (1+ failures)))))

  (dolist (sym ck/eca-upstream-guard--variables)
    (let ((ok (boundp sym)))
      (princ (format "%-46s var     %s\n" sym (if ok "OK" "MISSING")))
      (unless ok (setq failures (1+ failures)))))

  (dolist (pair ck/eca-upstream-guard--properties)
    (let* ((name (car pair))
           (library (cdr pair))
           (ok (ck/eca-upstream-guard--name-in-library-p name library)))
      (princ (format "%-46s prop@%-9s %s\n"
                     name library (if ok "OK" "MISSING")))
      (unless ok (setq failures (1+ failures)))))

  (if (zerop failures)
      (princ "PASS: every wrapped upstream symbol still exists\n")
    (princ (format "FAIL: %d wrapped upstream symbol(s) missing\n" failures))
    (kill-emacs 1)))

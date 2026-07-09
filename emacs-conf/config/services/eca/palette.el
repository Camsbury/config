;; -*- lexical-binding: t; -*-
;;; Command / skill palette --------------------------------------------------
;;
;; Slash commands and skills are annoying to type out.  Query the server for
;; the exact same catalog its `/' completion uses (native commands, skills,
;; custom prompts, MCP prompts, each with a description) and pick one with
;; `completing-read', inserting `/<name> ' at point so any arguments can be
;; typed.

(require 'prelude)
(require 'lib/utils)

(declare-functions "eca-util"
  eca-session
  eca-assert-session-running)
(declare-functions "eca-api"
  eca-api-request-sync)
(declare-functions "eca-chat"
  eca-chat--point-at-prompt-field-p
  eca-chat--insert)
(declare-vars eca-chat--id)

(defun ck/eca-chat--all-commands ()
  "Return the ECA server's full command/skill/prompt catalog for this chat.
Each entry is a plist with `:name', `:type', `:description', `:arguments'."
  (let ((session (eca-session)))
    (eca-assert-session-running session)
    (append
     (plist-get (eca-api-request-sync session
                                      :method "chat/queryCommands"
                                      :params (list :chatId eca-chat--id
                                                    :query ""))
                :commands)
     nil)))

(defun ck/eca-chat-insert-command ()
  "Pick an ECA command, skill or prompt via `completing-read' and insert it.
Lists everything the server exposes for `/' completion, with type and
description, and inserts `/<name> ' at the prompt so you never type the
name out (point is left after the space, ready for any arguments)."
  (interactive)
  (unless (derived-mode-p 'eca-chat-mode)
    (user-error "Not in an ECA chat buffer"))
  (let* ((commands (ck/eca-chat--all-commands))
         (width (apply #'max 1 (mapcar (lambda (c) (length (plist-get c :name)))
                                       commands)))
         (table (mapcar
                 (lambda (c)
                   ;; Emacs `format' has no C-style `%-*s' dynamic width, so
                   ;; pad the name to `width' explicitly.
                   (cons (format "%s  %-13s  %s"
                                 (string-pad (plist-get c :name) width)
                                 (format "(%s)" (or (plist-get c :type) ""))
                                 (or (plist-get c :description) ""))
                         c))
                 commands)))
    (unless table
      (user-error "No ECA commands available"))
    ;; Keep the server's catalog order (in-order read); resolve the selected
    ;; label string back to its plist through the table.
    (let* ((sel (ck/completing-read-in-order "ECA command: " table nil t))
           (cmd (cdr (assoc sel table)))
           (name (plist-get cmd :name)))
      (when name
        (unless (eca-chat--point-at-prompt-field-p)
          (goto-char (point-max)))
        (eca-chat--insert (concat "/" name " "))))))

(provide 'config/services/eca/palette)

;; -*- lexical-binding: t; -*-
;;; Deferred finish-time render ----------------------------------------------
;;
;; The LaTeX preview and table re-align are expensive whole-turn passes: a
;; buffer scan plus, for LaTeX, async render subprocesses.  Wired directly on
;; `eca-chat-finished-hook' they run for EVERY completed turn regardless of
;; where you are, so a chat that finishes while you are in a fullscreen game on
;; another EXWM workspace (or just another buffer) does that work anyway.  Emacs
;; is the window manager, so the redisplay/render churn hitches whatever you are
;; actually doing.
;;
;; Defer instead.  Render immediately only when you are LOOKING at the chat that
;; finished (it is the selected window's buffer); otherwise flag the buffer
;; pending and render lazily the instant you navigate into it.  The visible
;; result is identical; the cost just moves to when you are there to see it, off
;; whatever you were doing elsewhere.  The render clears the pending flag first,
;; so the selection hook can never re-enter a render.
;;
;; Scope note: only the LaTeX + table passes are deferred.  The transcript
;; size-bounding (`ck/eca-chat-window-if-needed', eca/windowing.el) stays on the
;; finished hook: it already self-defers, acting only when the chat is not the
;; selected window and running its work off the hook via a zero-delay timer.

(require 'prelude)

(declare-functions "config/services/eca/latex" ck/eca-chat--auto-preview-latex)
(declare-functions "config/services/eca/tables" ck/eca-chat--auto-align-tables)

(defvar-local ck/eca-chat--render-pending nil
  "Non-nil when this chat finished off-screen and its LaTeX/table render is
deferred until the buffer is next selected.")

(defun ck/eca-chat--render-finished-buffer ()
  "Run the deferred finish-time render (LaTeX preview + table align) for the
current buffer.  Clears the pending flag FIRST so a selection hook firing
during the render can never re-enter it."
  (setq ck/eca-chat--render-pending nil)
  (ck/eca-chat--auto-preview-latex)
  (ck/eca-chat--auto-align-tables))

(defun ck/eca-chat--render-or-defer ()
  "`eca-chat-finished-hook' entry: render now if you are viewing this chat,
else defer.  The hook runs with the finished chat buffer current; \"viewing\"
means it is also the selected window's buffer.  When it is not (you are in a
game, another buffer, another workspace) flag it pending so
`ck/eca-chat--render-pending-on-select' renders it when you navigate back."
  (when (derived-mode-p 'eca-chat-mode)
    (if (eq (current-buffer) (window-buffer (selected-window)))
        (ck/eca-chat--render-finished-buffer)
      (setq ck/eca-chat--render-pending t))))

(defun ck/eca-chat--render-pending-on-select (&rest _)
  "`window-selection-change-functions' entry: render a chat's deferred output
once you navigate into it.  The hook fires when the selected window or its
buffer changes; render only the newly selected buffer, and only when it carries
pending finish-time work."
  (let ((buf (window-buffer (selected-window))))
    (when (and (buffer-live-p buf)
               (buffer-local-value 'ck/eca-chat--render-pending buf))
      (with-current-buffer buf
        (ck/eca-chat--render-finished-buffer)))))

(provide 'config/services/eca/deferred-render)

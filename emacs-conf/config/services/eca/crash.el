;; -*- lexical-binding: t; -*-
;;; Crash mitigation: native code-block fontification -----------------------
;;
;; `eca-chat-mode' sets `markdown-fontify-code-blocks-natively' to t, which
;; makes markdown-mode spin up each fenced block's real major mode to
;; highlight it.  On Emacs 30.2 + native-comp that path can SIGSEGV deep in
;; the C core while fontifying a streamed code block, and because Emacs is the
;; window manager here that abort kills the whole X session (postmortem:
;; `.eca/docs/reference/theme-editor-crash-postmortem.md').  Disable native
;; code-block fontification in chat buffers: fenced blocks still render as
;; monospace via `markdown-code-face', only per-language highlighting (and
;; native diff coloring) is lost -- a cheap price to remove a session-fatal
;; crash path.  Runs on `eca-chat-mode-hook', after the mode body's own
;; `setq-local ... t', so it wins.

(require 'prelude)

(defun ck/eca--disable-native-code-fontify ()
  "Turn off native code-block fontification in the current ECA chat buffer.
Neutralizes the `markdown-fontify-code-blocks-natively' SIGSEGV path that can
take down the whole session (Emacs is the WM here)."
  (setq-local markdown-fontify-code-blocks-natively nil))

(provide 'config/services/eca/crash)

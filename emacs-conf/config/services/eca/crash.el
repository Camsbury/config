;; -*- lexical-binding: t; -*-
;;; Native code-block fontification: known crash path, mitigation DORMANT ----
;;
;; `eca-chat-mode' sets `markdown-fontify-code-blocks-natively' to t, which
;; makes markdown-mode spin up each fenced block's real major mode to
;; highlight it (per-language coloring plus green/red native diff coloring).
;; On Emacs 30.2 + native-comp that path CAN SIGSEGV deep in the C core while
;; fontifying a code block (a `delete-region' reentered by pending X input),
;; and because Emacs is the window manager here that abort kills the whole X
;; session.
;;
;; Native fontify is nonetheless ON: the crash needs an abnormal load, walls
;; of fenced code streamed into chat turn after turn, and the safeguard is
;; discipline about that (write code to files, keep chat lean).
;;
;; UNFOLDING a big collapsed block (a large tool result dumped into view at
;; once) reaches the same path without any streaming.
;; `config/services/eca/fold.el' size-gates both fold commands: past a byte
;; threshold it turns native code fontify off buffer-locally BEFORE the
;; reveal.  That is the live mitigation for the fold path; this dormant hook
;; is still the blunt whole-buffer opt-out if the crash ever recurs.
;;
;; This function is kept DORMANT (not wired to any hook).  To re-disable
;; native fontify if the crash recurs, add it back:
;;   (add-hook 'eca-chat-mode-hook #'ck/eca--disable-native-code-fontify)
;; and re-add the `(eca-chat-mode . ck/eca--disable-native-code-fontify)'
;; entry to the use-package `:hook' block in `config/services/eca.el'.

(require 'prelude)

(defun ck/eca--disable-native-code-fontify ()
  "Turn off native code-block fontification in the current ECA chat buffer.
Neutralizes the `markdown-fontify-code-blocks-natively' SIGSEGV path that can
take down the whole session (Emacs is the WM here).  Dormant by default; see
this file's header for when and how to re-enable it."
  (setq-local markdown-fontify-code-blocks-natively nil))

(provide 'config/services/eca/crash)

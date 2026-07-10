;; -*- lexical-binding: t; -*-
;;; Native code-block fontification: known crash path, mitigation DORMANT ----
;;
;; `eca-chat-mode' sets `markdown-fontify-code-blocks-natively' to t, which
;; makes markdown-mode spin up each fenced block's real major mode to
;; highlight it (per-language coloring plus green/red native diff coloring).
;; On Emacs 30.2 + native-comp that path CAN SIGSEGV deep in the C core while
;; fontifying a code block (a `delete-region' reentered by pending X input --
;; the same reentrant-teardown class as BUG-2), and because Emacs is the
;; window manager here that abort kills the whole X session.  Full postmortem:
;; `.eca/docs/reference/theme-editor-crash-postmortem.md'.
;;
;; History / decision (2026-07-06): this fired exactly ONCE (2026-07-05,
;; ~85% confidence), under an abnormal load -- a peer agent streaming 150-250
;; line walls of elisp/EDN fenced blocks into chat, turn after turn.  Native
;; fontify had been on for MONTHS of normal use with no crash, and ECA ships
;; it on by default.  Disabling it after that single stressed data point was
;; an overreaction, so the mitigation is REMOVED from the hook and native
;; fontify is on again.  Two later changes cut the crash exposure further:
;; `eca-chat-fontify-debounce-interval' set to nil (no repeated mid-stream
;; full-turn re-fontify) and the idle-GC work (fewer GC-timing collisions).
;; The real safeguard remains discipline: write code to files, keep chat lean
;; -- that is what starves this crash (never stream big code walls into chat).
;;
;; A SECOND trigger of this same path is UNFOLDING a big collapsed block (a
;; large tool result dumped into view at once), independent of streaming.
;; `config/services/eca/fold.el' now size-gates both fold commands: past a
;; byte threshold it turns native code fontify off buffer-locally BEFORE the
;; reveal, so a huge unfold renders as cheap monospace instead of freezing /
;; SIGSEGV-ing.  That is the live mitigation for the fold path; this dormant
;; hook is still the blunt whole-buffer opt-out if the crash ever recurs.
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

;; -*- lexical-binding: t; -*-
;;; ECA chat integration -----------------------------------------------------
;;
;; Personal ECA (Editor Code Assistant) chat customizations, split across the
;; `config/services/eca/' subdirectory.  This aggregator owns the shared
;; customization group, pulls in the feature files listed in the `m-require'
;; below (each carries its own commentary), and wires the `eca' package itself
;; (hooks, window placement, and the `eca-chat-mode-map' bindings that must
;; wait for eca to load).

(require 'prelude)
;; general-def comes from here.  The one hub symbol this file names,
;; ck/empty-mode-leader, is a runtime remap target (suppressed below), not a
;; load-time dependency; the hub loads earlier at boot regardless.
(require 'core/definers)

(defgroup ck/eca nil
  "Personal ECA chat customizations."
  :group 'cmacs)

;;; Server version pin -------------------------------------------------------
;; Left to itself, eca-emacs floats the server to GitHub's newest release on
;; every startup (its "latest server version" lookup).  We pin it so the
;; server moves only when we say so, in lockstep with the eca-emacs client
;; pinned in nix-conf/overlays/emacs.nix.  This value and that overlay are
;; rewritten together by scripts/update-eca.bb; do not hand-edit one alone.
;; The adapter override (registered after the require list below) makes the
;; pin the ONE source of truth: the download decision, the release URL, and
;; the on-disk eca-version marker all use it, so they cannot disagree and
;; strand the session on a stale binary.
(defvar ck/eca-server-version "0.161.1"
  "Pinned eca server version (a github.com/editor-code-assistant/eca release tag).")

(defun ck/eca--pinned-server-version (&rest _)
  "Return `ck/eca-server-version', ignoring GitHub's latest release."
  ck/eca-server-version)

(m-require config/services/eca
  upstream
  pair
  latex
  tables
  deferred-render
  tabs
  window
  compose
  palette
  crash
  fold
  windowing
  pending
  scroll
  nav
  colors
  keys)

;; Registered here rather than from a satellite: the pin is aggregator-owned
;; (see the defvar above).
(ck/eca-upstream-set-server-version-source #'ck/eca--pinned-server-version)

(declare-vars eca-chat-mode-map)

;;; Package setup -----------------------------------------------------------

(use-package eca
  ;; init.el restricts `package-load-list', so the package's own autoloads
  ;; never load; stub the entry command ourselves or nothing defines `eca'.
  :commands (eca)
  :hook
  (eca-chat-mode . (lambda () (whitespace-mode -1)))
  (eca-chat-mode . ck/eca--sweep-on-chat-kill)
  (eca-chat-mode . ck/eca-chat--apply-table-font)
  :config
  (setq eca-chat-use-side-window nil)

  ;; Stream without the intermediate fontify debounce: nil means "no
  ;; mid-stream font-lock, jit-lock still colors the visible area, and one
  ;; final ensure runs at end-of-stream" (ECA's blessed mode; finished output
  ;; is identical, only off-screen streaming text stays uncolored until
  ;; scrolled to or done).  The stock timer re-ran `font-lock-ensure' over the
  ;; whole growing turn on every fire, which is O(n^2) buffer scanning on a
  ;; long answer.  nil also cuts how often native code-block fontify sweeps a
  ;; stream, lowering the reentrant-mutation SIGSEGV exposure (see
  ;; eca/crash.el).
  (setq eca-chat-fontify-debounce-interval nil)

  ;; Window placement for eca chats:
  ;; - re-displaying the current chat reuses its window;
  ;; - a chat whose ECA workspace is already on screen toggles into that
  ;;   window (same-workspace chats share one window);
  ;; - the first chat of a workspace spawns leftmost (full height, from the
  ;;   whole frame); prettify then sizes it to `prettify-width' cols once the
  ;;   layout settles.
  (add-to-list 'display-buffer-alist
               '("\\`<eca-chat"
                 (display-buffer-reuse-window
                  ck/eca-display-reuse-same-workspace-window
                  display-buffer-in-direction)
                 (direction . left)
                 (window . root)
                 (body-function . (lambda (_w) (ck/prettify-windows)))))

  ;; Finish-time render is DEFERRED (see eca/deferred-render.el): the LaTeX and
  ;; table passes run only when you are viewing the finished chat, or the
  ;; moment you next navigate into it.  The transcript size-bounding stays on
  ;; finish; it already self-defers.
  (add-hook 'eca-chat-finished-hook #'ck/eca-chat--render-or-defer)
  (add-hook 'window-selection-change-functions
            #'ck/eca-chat--render-pending-on-select)
  (add-hook 'eca-chat-finished-hook #'ck/eca-chat-window-if-needed)
  ;; A selected chat is queued but not rebuilt under the user's cursor.  The
  ;; next command after leaving it dispatches the deferred bounded replay.
  (add-hook 'post-command-hook #'ck/eca-chat--schedule-window-dispatch)

  ;; Every advice on an eca internal is owned by the ECA upstream adapter
  ;; (eca/upstream.el); each satellite self-registers its handler through the
  ;; adapter's extension points at its own load time, before this deferred
  ;; package loads, so the adapter's dispatch advice attaches to the not-yet-
  ;; defined upstream symbol and applies once eca defines it.

  ;; `C-c C-c' toggles the prompt into (and, from the compose buffer, back
  ;; out of) a dedicated edit buffer: one chord either direction.  Bound
  ;; outside an evil state so it works whether typing (insert) or navigating
  ;; (normal) in the prompt.
  (define-key eca-chat-mode-map (kbd "C-c C-c") #'ck/eca-toggle-compose)

  ;; Expandable-block folding: plain TAB folds the block at *or around* point
  ;; (not just from its header line); shift-TAB toggles every block; `M-j' /
  ;; `M-k' walk to the next / previous block header.
  (define-key eca-chat-mode-map (kbd "<tab>")     #'ck/eca-chat-tab-dwim)
  (define-key eca-chat-mode-map (kbd "TAB")       #'ck/eca-chat-tab-dwim)
  (define-key eca-chat-mode-map (kbd "<backtab>") #'ck/eca-chat-toggle-all-blocks)
  (define-key eca-chat-mode-map (kbd "S-<tab>")   #'ck/eca-chat-toggle-all-blocks)
  (define-key eca-chat-mode-map (kbd "M-k") #'eca-chat-go-to-prev-expandable-block)
  (define-key eca-chat-mode-map (kbd "M-j") #'eca-chat-go-to-next-expandable-block)

  (general-def 'normal eca-chat-mode-map
    [remap ck/empty-mode-leader]     #'hydra-eca/body))

(provide 'config/services/eca)

;; Aggregator + use-package config: the "undefined" symbols are the ck/eca-*
;; operations and hydras defined in the sibling feature files, pulled in by the
;; `m-require' above (a runtime require, invisible to the isolated
;; byte-compiler) and invoked only when the deferred `eca' package loads.
;; Suppress the unresolved class; keep every other class live.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

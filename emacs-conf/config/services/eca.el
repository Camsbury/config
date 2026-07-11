;; -*- lexical-binding: t; -*-
;;; ECA chat integration -----------------------------------------------------
;;
;; Personal ECA (Editor Code Assistant) chat customizations, split across the
;; `config/services/eca/' subdirectory.  This aggregator owns the shared
;; customization group, pulls in the feature files, and wires the `eca'
;; package itself (hooks, window placement, the config-isolation advices, and
;; the `eca-chat-mode-map' bindings that must wait for eca to load).
;;
;; Feature files (see each for its own commentary):
;;   latex     LaTeX-fragment image previews in chat buffers
;;   tables    re-align every table + a wrapped reading view
;;   tabs      close/delete a chat tab + sweep closed buffers
;;   window    workspace-scoped chat window reuse
;;   isolation per-chat agent/model config isolation (+ server registration)
;;   compose   dedicated prompt compose buffer
;;   palette   command/skill/prompt picker
;;   crash     dormant opt-in to re-disable native code-block fontify
;;   fold      fold expandable blocks from inside their content
;;   scroll    follow the stream only while point is in the prompt
;;   nav       jump/rotation navigation across all chats
;;   colors    make the context-usage bar inherit the doom theme
;;   keys      the in-chat and global navigation hydras

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
;; every startup (`eca-process--get-latest-server-version').  We pin it so the
;; server moves only when we say so, in lockstep with the eca-emacs client
;; pinned in nix-conf/overlays/emacs.nix.  This value and that overlay are
;; rewritten together by scripts/update-eca.bb; do not hand-edit one alone.
;; The override below makes the pin the ONE source of truth: the download
;; decision, the release URL, and the on-disk eca-version marker all use it,
;; so they can never disagree (the drift that stranded us on a stale binary).
(defvar ck/eca-server-version "0.145.1"
  "Pinned eca server version (a github.com/editor-code-assistant/eca release tag).")

(defun ck/eca--pinned-server-version (&rest _)
  "Return `ck/eca-server-version', ignoring GitHub's latest release."
  ck/eca-server-version)

(m-require config/services/eca
  latex
  tables
  tabs
  window
  isolation
  compose
  palette
  crash
  fold
  scroll
  nav
  colors
  keys)

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
  ;; scrolled to or done).  The stock 0.15s timer re-ran `font-lock-ensure'
  ;; over the whole growing turn on every fire: O(n^2) buffer-substring
  ;; scans on long answers, the string-alloc bursts that tripped whole-heap
  ;; GCs.  nil also cuts how often native code-block fontify sweeps a stream,
  ;; lowering the reentrant-mutation SIGSEGV exposure (see eca/crash.el).
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

  (add-hook 'eca-chat-finished-hook #'ck/eca-chat--auto-preview-latex)
  (add-hook 'eca-chat-finished-hook #'ck/eca-chat--auto-align-tables)

  (advice-add 'eca-process-stop :after #'ck/eca--sweep-closed-buffers)
  (advice-add 'eca-chat-exit    :after #'ck/eca--sweep-closed-buffers)

  ;; Make the context-usage bar inherit the doom theme instead of the
  ;; server-sent hex colors: strip the per-category `:color' / free
  ;; `:freeColor' before these resolvers see them, so they fall through to
  ;; the client faces (themed in `config/theme/doom-*.edn' ->
  ;; `eca-chat-context-*-face').  See eca/colors.el.
  (dolist (fn '(eca-chat--context-category-color
                eca-chat--context-category-face-spec))
    (advice-add fn :filter-args #'ck/eca--strip-cat-color))
  (dolist (fn '(eca-chat--context-free-color
                eca-chat--context-free-face-spec))
    (advice-add fn :filter-args #'ck/eca--strip-free-color))

  ;; Only follow the stream (yank point to the bottom + recenter) while point
  ;; is in the prompt field; reading up in the transcript mid-stream leaves the
  ;; cursor put.  See eca/scroll.el.
  (advice-add 'eca-chat--ensure-prompt-visible
              :before-while #'ck/eca-chat--follow-only-in-prompt)
  ;; Pin the server version (see the defvar above); :override so eca never
  ;; contacts GitHub to decide "latest".
  (advice-add 'eca-process--get-latest-server-version
              :override #'ck/eca--pinned-server-version)

  (advice-add 'eca-config-updated
              :around #'ck/eca--config-updated-attach-chat-id)
  (advice-add 'eca-chat-config-updated
              :around #'ck/eca--config-updated-guard-globals)
  (dolist (fn '(eca-chat--set-agent
                eca-chat-select-model
                eca-chat-select-variant))
    (advice-add fn :around #'ck/eca--shadow-config-globals))

  ;; `C-c C-c' toggles the prompt into (and, from the compose buffer, back
  ;; out of) a dedicated edit buffer -- one chord either direction.  Bound
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

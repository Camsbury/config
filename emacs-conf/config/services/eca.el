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
;;   crash     disable the session-fatal native code-block fontify path
;;   nav       jump/rotation navigation across all chats
;;   keys      the in-chat and global navigation hydras

(require 'prelude)
(require 'core/bindings)

(defgroup ck/eca nil
  "Personal ECA chat customizations."
  :group 'cmacs)

(m-require config/services/eca
  latex
  tables
  tabs
  window
  isolation
  compose
  palette
  crash
  nav
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
  (eca-chat-mode . ck/eca--disable-native-code-fontify)
  :config
  (setq eca-chat-use-side-window nil)

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

  (general-def 'normal eca-chat-mode-map
    [remap ck/empty-mode-leader]     #'hydra-eca/body))

(provide 'config/services/eca)

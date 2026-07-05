;; -*- lexical-binding: t; -*-
;;; ECA hydras ---------------------------------------------------------------
;;
;; The in-chat mode hydra and the global navigation hydra.  The commands they
;; bind live in the sibling feature files, required below so the bindings
;; resolve and load order is explicit.  The `eca-chat-mode-map' wiring (which
;; needs the map, and so must wait for eca to load) lives in the package
;; `:config' in the aggregator, not here.

(require 'prelude)
(require 'core/bindings)
(require 'config/services/eca/latex)
(require 'config/services/eca/tables)
(require 'config/services/eca/tabs)
(require 'config/services/eca/compose)
(require 'config/services/eca/palette)
(require 'config/services/eca/isolation)
(require 'config/services/eca/nav)

(declare-functions "eca-chat"
  eca-chat-clear-prompt
  eca-chat-select-agent
  eca-chat-select-model
  eca-chat-select-variant
  eca-chat-select
  eca-chat-rename
  eca-chat-resume)
(declare-functions "eca" eca eca-stop)
(declare-functions "tab-line"
  tab-line-switch-to-next-tab
  tab-line-switch-to-prev-tab)

(defhydra hydra-eca (:exit t :columns 5)
  "eca-chat-mode"
  ("c" #'eca-chat-clear-prompt "Clear prompt")
  ("p" #'ck/eca-chat-edit-prompt "Edit prompt (compose)")
  ("a" #'eca-chat-select-agent "Select agent")
  ("m" #'eca-chat-select-model "Select the model")
  ("o" #'ck/eca-chat-new-registered "New chat")
  ("t" #'eca-chat-select "Select chat")
  ("e" #'eca-chat-resume "Open server chat")
  ("f" #'ck/eca-chat-insert-command "Insert command/skill")
  ("n" #'eca-chat-rename "Rename chat")
  ("v" #'eca-chat-select-variant "Select the variant")
  ("l" #'tab-line-switch-to-next-tab "Next tab")
  ("h" #'tab-line-switch-to-prev-tab "Prev tab")
  ("k" #'ck/eca-chat-close-tab "Close tab")
  ("K" #'ck/eca-chat-delete-tab "Close tab + delete chat")
  ("L" #'ck/eca-chat-toggle-latex "Toggle LaTeX")
  ("b" #'ck/eca-chat-align-tables "Align tables")
  ("T" #'ck/eca-chat-open-table-wrapped "Open table (wrapped)")
  ("q" #'eca-stop "Stop ECA if running")
  )

;; Global ECA navigation, reachable from anywhere (bound on the leader as
;; `SPC s' / `s-SPC s', and to the `s-e' EXWM chord for attention).  Sticky by
;; default (like `hydra-merge') so the rotation heads can be pressed
;; repeatedly to sweep every waiting/idle chat; `u' and `q' exit.
(defhydra hydra-eca-nav (:columns 4)
  "eca nav"
  ("j" #'ck/eca-jump-to-attention      "attention next")
  ("k" #'ck/eca-jump-to-attention-back "attention prev")
  ("i" #'ck/eca-jump-to-idle           "idle next")
  ("n" #'ck/eca-jump-next              "chat next")
  ("p" #'ck/eca-jump-prev              "chat prev")
  ("u" #'eca                           "open eca" :exit t)
  ("q" nil                             "quit"))

(provide 'config/services/eca/keys)

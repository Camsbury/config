;; -*- lexical-binding: t; -*-
(require 'prelude)

;; Foundational keybinding macro providers, extracted from the core/bindings
;; hub so any keybinding file can `(require 'core/definers)' and have its
;; binding macros EXPAND in byte-compile isolation, instead of silently
;; depending on the hub having loaded first.  What this makes available:
;;   - evil: `evil-define-operator', `evil-define-key', the state maps.
;;   - general: `general-def'/`general-define-key'/`general-key-dispatch', plus
;;     the evil short definers `nmap'/`imap'/`vmap'/... that `general-evil-setup'
;;     generates at LOAD time (so they cannot expand unless it has run).
;;   - `defhydra' (the hydra macro).
;;
;; This is wiring PRIMITIVES (macro providers), pulled in on demand.  It does no
;; application wiring itself: no keymaps, hooks, hydra bodies, or key bindings
;; live here.  evil is already set up by core/text (the survival kit) before the
;; hub loads, so `(require 'evil)' here is a boot-time no-op and only matters for
;; isolated compilation.

(require 'evil)
;; general-evil-setup is defined by general; the `:config' below runs after
;; general loads, so it is bound at runtime.  Declare it for the isolated
;; byte-compiler, which cannot see through the deferred `:config'.
(declare-functions "general" general-evil-setup)
(use-package general
  :config
  (general-evil-setup t))
(use-package hydra)

(provide 'core/definers)

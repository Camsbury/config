;; -*- lexical-binding: t; -*-
;; general/hydra macros (general-add-hook, general-def, defhydra) expand from
;; here instead of depending on the core/bindings hub loading first.
(require 'core/definers)
(use-package nov)
(add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))

(setq nov-text-width 80)

;; make this thing monospaced
(setq nov-variable-pitch nil)

(general-add-hook 'nov-mode-hook
                  'evil-mode)

(general-def 'normal nov-mode-map
 [remap ck/empty-mode-leader] #'hydra-nov/body)

(defhydra hydra-nov (:exit t)
  "nov-mode"
  ("t" #'nov-goto-toc          "table of contents")
  ("h" #'nov-previous-document "back")
  ("l" #'nov-next-document     "next"))

(provide 'config/viewers/epub)

;; Keybinding/hydra file: the nov-* commands are deferred package API, invoked
;; only at runtime.  Suppress just the unresolved class; every other class stays
;; live.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

;; -*- lexical-binding: t; -*-
(require 'prelude)
;; defhydra/general-def macros come from here, so they expand in byte-compile
;; isolation instead of depending on the core/bindings hub.
(require 'core/definers)
(use-package idris-mode
  :mode "\\.idr\\'"
  :interpreter "idris")

(general-def 'normal idris-mode-map
  [remap ck/empty-mode-leader]    #'hydra-idris/body
  [remap evil-goto-definition] #'idris-docs-at-point)

(defhydra hydra-idris (:exit t)
  "idris-mode"
  ("b" #'idris-add-clause      "add body")
  ("f" #'idris-make-lemma      "extract function")
  ("l" #'idris-load-file       "load file")
  ("r" #'idris-proof-search    "proof search")
  ("s" #'idris-case-dwim       "split at point")
  ("t" #'idris-type-at-point   "type at point")
  ("o" #'idris-repl            "repl")
  ("w" #'idris-make-with-block "put into with"))

(provide 'config/langs/idris)

;; use-package config + hydra: forward-refs deferred idris commands invoked only
;; at runtime.  Suppress just the unresolved class.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

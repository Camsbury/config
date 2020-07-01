(use-package bindings-conf)
(use-package functions-conf)

(general-def 'normal idris-mode-map
  [remap empty-mode-leader]    #'hydra-idris/body
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

(provide 'langs/idris-conf)

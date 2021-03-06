(use-package racket-mode
  :defer t)

(general-def 'normal racket-mode-map
 [remap empty-mode-leader] #'hydra-racket/body
 )

(defhydra hydra-racket (:exit t)
  "racket-mode"
 ("l" 'racket-repl                   "repl")
 ("r" 'racket-run-and-switch-to-repl "run and repl")
 ("t" 'racket-test                   "test"))

(provide 'config/langs/racket)

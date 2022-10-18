(require 'prelude)
(use-package racket-mode)
(use-package hydra)

(general-def 'normal racket-mode-map
 [remap empty-mode-leader] #'hydra-racket/body
 )

(general-add-hook
 'racket-mode-hook
 (list
  'paredit-mode
  'lispyville-mode
  'flycheck-mode))

(defhydra hydra-racket (:exit t)
  "racket-mode"
 ("r" #'racket-repl                   "repl")
 ("l" #'racket-run-and-switch-to-repl "run and repl")
 ("t" #'racket-test                   "test"))

(provide 'config/langs/racket)

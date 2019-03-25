(require 'bindings-conf)
(require 'functions-conf)

(general-def 'normal ess-r-mode-map
  [remap empty-mode-leader] #'hydra-r/body)

(defhydra hydra-r (:exit t)
  "ess-r-mode"
  ("b" #'ess-eval-buffer "eval buffer")
  ("l" #'ess-eval-line   "eval line")
  ("r" #'ess-eval-region "eval region"))

(provide 'rlang-conf)

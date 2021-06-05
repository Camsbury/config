(use-package ess)
(general-def 'normal ess-r-mode-map
  [remap empty-mode-leader] #'hydra-r/body
  [remap ess-use-this-dir]  #'ess-eval-region-or-function-or-paragraph)

(defhydra hydra-r (:exit t)
  "ess-r-mode"
  ("b" #'essk-eval-buffer "eval buffer")
  ("l" #'ess-eval-line   "eval line")
  ("r" #'ess-eval-region "eval region"))

(provide 'config/langs/rlang)

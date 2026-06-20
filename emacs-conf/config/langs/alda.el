;; -*- lexical-binding: t; -*-
(use-package alda-mode
  :mode "\\.alda\\'"
  :interpreter "alda")

(general-def 'normal alda-mode-map
 [remap ck/empty-mode-leader] #'hydra-alda/body)

(defhydra hydra-alda (:exit t)
  "alda-mode"
  ("l" #'alda-play-line "play line")
  ("f" #'alda-play-file "play file"))

(provide 'config/langs/alda)

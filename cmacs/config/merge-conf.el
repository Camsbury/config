;; Bindings for smerge
(use-package hydra)

;;; smerge bindings
(defhydra hydra-merge ()
  "merge"
  ("a" #'smerge-keep-all "keep all")
  ("u" #'smerge-keep-upper "keep upper")
  ("l" #'smerge-keep-lower "keep lower")
  ("p" #'smerge-prev "previous")
  ("n" #'smerge-next "next")
  ("z" #'evil-scroll-line-to-center "center")
  ("q" nil "quit" :color red))

(provide 'merge-conf)

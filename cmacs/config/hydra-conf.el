(require 'hydra)

(defhydra hydra-merge ()
  "merge"
  ("a" #'smerge-keep-all "keep all")
  ("u" #'smerge-keep-upper "keep upper")
  ("l" #'smerge-keep-lower "keep lower")
  ("p" #'smerge-prev "previous")
  ("n" #'smerge-next "next")
  ("q" nil "quit" :color red))

(provide 'hydra-conf)

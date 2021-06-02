(use-package asoc)
(use-package async)
(use-package dash)
(use-package f)
(use-package ht)
(use-package ls)
(use-package s)
(use-package ts)
(use-package with-simulated-input)

(defmacro comment (&rest _body)
  "Comment out one or more s-expressions"
  nil)

(defun inc (x) "Returns x + 1" (+ 1 x))
(defun dec (x) "Returns x - 1" (- x 1))

(provide 'prelude)

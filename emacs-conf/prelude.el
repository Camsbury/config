(use-package dash)
(use-package dash-functional)
(use-package f)
(use-package s)

(defmacro comment (&rest _body)
  "Comment out one or more s-expressions"
  nil)

(defun inc (x) "Returns x + 1" (+ 1 x))
(defun dec (x) "Returns x - 1" (- x 1))

(provide 'prelude)

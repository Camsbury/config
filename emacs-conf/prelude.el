(use-package dash)
(use-package dash-functional)
(use-package f)
(use-package s)

(defun c--ns->path (ns)
  (->> ns
       (nth 1)
       symbol-name
       (s-replace "." "/")
       intern))

(defmacro c-require (ns)
  `(require ',(c--ns->path ns)))

(defmacro c-provide (ns)
  `(provide ',(c--ns->path ns)))

(defmacro comment (&rest _body)
  "Comment out one or more s-expressions"
  nil)

(defun inc (x) "Returns x + 1" (+ 1 x))
(defun dec (x) "Returns x - 1" (- x 1))

(provide 'prelude)

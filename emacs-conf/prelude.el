(require 'use-package)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Elisp Libraries

(use-package asoc)
(use-package async)
(use-package dash)
(use-package f)
(use-package ht)
(use-package parseedn)
(use-package s)
(use-package ts)
(use-package uuidgen)
(use-package with-simulated-input)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Clojure-like features

(defmacro comment (&rest _body)
  "Comment out one or more s-expressions"
  nil)
(defun inc (x) "Returns x + 1" (+ 1 x))
(defun dec (x) "Returns x - 1" (- x 1))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Easy Readers

(defmacro m-require (prefix &rest args)
  "Pull in all features for a given prefix"
  (declare (indent 1))
  `(-each
       ',(--map
          (intern
           (concat
            (symbol-name prefix)
            "/"
            (symbol-name it)))
          args)
     'require))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Etc.

(defun random-choice (items)
  (let* ((size (length items))
         (index (random size)))
    (nth index items)))

(defun unadvise (sym)
  "Remove all advice from symbol SYM."
  (interactive "aFunction symbol: ")
  (advice-mapc (lambda (advice _props) (advice-remove sym advice)) sym))

(provide 'prelude)

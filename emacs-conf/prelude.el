;; -*- lexical-binding: t; -*-
(require 'use-package)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Elisp Libraries

(use-package a)
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
;;; Byte-compile forward declarations

(defmacro declare-functions (file &rest names)
  "Declare each of NAMES as a function defined in FILE.
Expands to one `declare-function' per name, so byte-compiling code that
calls into a deferred package stays warning-free without force-loading
that package.  Groups the otherwise noisy per-function boilerplate:

  (declare-functions \"eca-chat\" eca-chat--insert eca-chat--set-prompt)"
  (declare (indent 1))
  `(progn ,@(mapcar (lambda (name) `(declare-function ,name ,file)) names)))

(defmacro declare-vars (&rest names)
  "Forward-declare each of NAMES as a special variable for the byte-compiler.
Expands to a value-less `defvar' per name, silencing free-variable
warnings for vars a deferred package owns without touching their values."
  (declare (indent 0))
  `(progn ,@(mapcar (lambda (name) `(defvar ,name)) names)))


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

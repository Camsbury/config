;; -*- lexical-binding: t; no-byte-compile: t; -*-
(require 'prelude)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test Jumping

;; CLEAN: get multimethods and just dispatch per mode...
;; https://github.com/skeeto/predd
;; (also have some kind of local config in dir-locals)

(defun ck/jump-to-test-clojure ()
  "Jump from a clojure namespace to a test."
  (interactive)
  (let ((filename (->> buffer-file-name
                       (s-replace "/src/" "/test/")
                       (s-replace ".clj" "_test.clj"))))
    (make-directory (f-dirname filename) t)
    (find-file filename)))

(defun ck/jump-from-test-clojure ()
  "Jump from a test to a clojure namespace."
  (interactive)
  (let ((filename (->> buffer-file-name
                       (s-replace "/test/" "/src/")
                       (s-replace "_test.clj" ".clj"))))
    (make-directory (f-dirname filename) t)
    (find-file filename)))

(defun ck/toggle-test-clojure ()
  "Toggle test and source in clojure."
  (interactive)
  (if (s-contains? "/src/" buffer-file-name)
      (ck/jump-to-test-clojure)
    (ck/jump-from-test-clojure)))

(defun ck/toggle-tests ()
  "Toggle test and source"
  (interactive)
  (cl-case major-mode
    ('clojure-mode (ck/toggle-test-clojure))
    (t (message "mode not supported for test toggling"))))


(provide 'config/dev/test)

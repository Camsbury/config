;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test Jumping

;; CLEAN: get multimethods and just dispatch per mode...
;; (also have some kind of local config in dir-locals)

;; (defun jump-to-test-haskell ()
;;   "Jump from a haskell module to a test."
;;   (let ((filename (->> buffer-file-name
;;                        (s-replace "/src/" "/test/")
;;                        (s-replace ".hs" "Test.hs"))))
;;     (make-directory (f-dirname filename) t)
;;     (find-file filename)))

;; (defun jump-from-test-haskell ()
;;   "Jump from a test to a haskell module."
;;   (let ((filename (->> buffer-file-name
;;                        (s-replace "/test/" "/src/")
;;                        (s-replace "Test.hs" ".hs"))))
;;     (make-directory (f-dirname filename) t)
;;     (find-file filename)))

;; (defun toggle-test-haskell ()
;;   "Toggle test and source in Haskell."
;;   (if (s-contains? "/src/" buffer-file-name)
;;       (jump-to-test-haskell)
;;     (jump-from-test-haskell)))

;; (defun toggle-test ()
;;   "Toggle between test and source."
;;   (interactive)
;;   (when (s-contains? ".hs" buffer-file-name)
;;     (toggle-test-haskell)))


(provide 'dev/test)

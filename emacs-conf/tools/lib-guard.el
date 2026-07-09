;;; lib-guard.el --- fail when a lib/ feature stops being a library -*- lexical-binding: t; -*-
;;
;; Batch payload for lib-guard.sh.  `lib/' is the wiring-free layer of the
;; library/application seam (decision 0009): every feature there must
;; classify `library' under `cmacs-deps-classify' (definitions only, no
;; use-package/keybinding/hook/advice heads reachable at load time).  This
;; guard machine-checks that invariant; a FAIL means someone added wiring to
;; a lib/ file (move the wiring to an application file instead).
;;
;; Run via tools/lib-guard.sh (resolves the emacs binary + EMACSLOADPATH
;; from the cmacs launcher; see the harness-fidelity gotcha).

(let* ((here (file-name-directory load-file-name))
       (root (directory-file-name (expand-file-name ".." here))))
  (add-to-list 'load-path root)
  (load (expand-file-name "cmacs-deps.el" here) nil t)
  (let ((files (directory-files (expand-file-name "lib" root) t "\\.el\\'"))
        (failures 0))
    (unless files
      (princ "lib-guard: no files under lib/\n")
      (kill-emacs 2))
    (dolist (f files)
      (let* ((pl (cmacs-deps-classify f))
             (class (plist-get pl :class))
             (ok (eq class 'library)))
        (princ (format "%-40s %-12s%s\n"
                       (file-relative-name f root)
                       class
                       (if ok ""
                         (format "  evidence=%S" (plist-get pl :evidence)))))
        (unless ok (setq failures (1+ failures)))))
    (if (zerop failures)
        (princ "PASS: every lib/ feature classifies library\n")
      (princ (format "FAIL: %d lib/ file(s) classify as wiring\n" failures))
      (kill-emacs 1))))

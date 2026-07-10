;; -*- lexical-binding: t; -*-
(require 'prelude)

;; CIDER and its nREPL/sesman deps load lazily with clojure-mode.  Every use
;; below is inside an interactive defun (runtime), so forward-declare them
;; rather than force-load CIDER at config time (see prelude's
;; `declare-functions').
(declare-functions "cider"
  cider-interactive-eval
  cider-insert-in-repl
  cider-sexp-at-point
  cider-emit-interactive-eval-output
  cider-emit-interactive-eval-err-output
  cider-nrepl-sync-request:eval
  cider-jack-in-clj&cljs
  cider-inspect)
(declare-functions "nrepl-client" nrepl-make-response-handler)
(declare-functions "sesman" sesman-quit)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Functions

(defun ck/clerk-show ()
  (interactive)
  (save-buffer)
  (let
      ((filename
        (buffer-file-name)))
    (when filename
      (cider-interactive-eval
       (concat "(nextjournal.clerk/show! \"" filename "\")")))))

(defun ck/clerk-show-tap ()
  (interactive)
  (let ((filename
         (buffer-file-name)))
    (when filename
      (cider-interactive-eval
       "(nextjournal.clerk/show! 'nextjournal.clerk.tap)"))))

(defun ck/cider-copy-last-result ()
  (interactive)
  (cider-interactive-eval
   "*1"
   (nrepl-make-response-handler
    (current-buffer)
    (lambda (_ value)
      (kill-new value)
      (message "Copied last result (%s) to clipboard"
               (if (= (length value) 1) "1 char"
                 (format "%d chars" (length value)))))
    nil nil nil)))

(defun ck/cider-remove-pprint-commas
    (s)
  (let ((inner-string-p nil)
        (escaped-p nil))
    (apply #'string
           (reverse
            (--reduce-from
             (progn
               (when (and (not escaped-p) (eq it ?\"))
                 (setq inner-string-p (not inner-string-p)))
               (if escaped-p
                   (setq escaped-p nil)
                 (when (eq it ?\\)
                   (setq escaped-p t)))
               (if (and (not inner-string-p) (eq it ?,))
                   acc
                 (cons it acc)))
             nil
             (-map (lambda (x) x) s))))))

;; TODO: don't remove commas if it's just a string
(defun ck/cider-copy-last-result-dwim ()
  (interactive)
  (cider-interactive-eval
   "(with-out-str (clojure.pprint/pprint *1))"
   (nrepl-make-response-handler
    (current-buffer)
    (lambda (_ value)
      (if (string-match "^\"" (read value))
          (kill-new (read (read value)))
        (kill-new (ck/cider-remove-pprint-commas (read value))))
      (message "Copied last result (%s) to clipboard"
               (if (= (length value) 1) "1 char"
                 (format "%d chars" (length value)))))
    nil nil nil)))

(defun ck/cider-copy-last-result-as-edn ()
  (interactive)
  (cider-interactive-eval
   "(with-out-str (clojure.pprint/pprint *1))"
   (nrepl-make-response-handler
    (current-buffer)
    (lambda (_ value)
      (kill-new (ck/cider-remove-pprint-commas (read value)))
      (message "Copied last result (%s) to clipboard"
               (if (= (length value) 1) "1 char"
                 (format "%d chars" (length value)))))
    nil nil nil)))

(defun ck/cider-insert-current-sexp-in-repl (&optional arg)
  "Insert the expression at point in the REPL buffer.
If invoked with a prefix ARG eval the expression after inserting it"
  (interactive "P")
  (cider-insert-in-repl (cider-sexp-at-point) arg))

(defun ck/+clojure-pprint-expr (form)
  (format "(with-out-str (clojure.pprint/pprint %s))"
          form))

(defun ck/cider-eval-read-and-print-handler (&optional buffer)
  "Make a handler for evaluating and reading then printing result in BUFFER."
  (nrepl-make-response-handler
   (or buffer (current-buffer))
   (lambda (buffer value)
     (let ((value* (read value)))
       (with-current-buffer buffer
         (insert
          (if (derived-mode-p 'cider-clojure-interaction-mode)
              (format "\n%s\n" value*)
            value*)))))
   (lambda (_buffer out) (cider-emit-interactive-eval-output out))
   (lambda (_buffer err) (cider-emit-interactive-eval-err-output err))
   '()))

(defun ck/cider-eval-and-replace (beg end)
  "Evaluate the expression in region and replace it with its result"
  (interactive "r")
  (let ((form (buffer-substring beg end)))
    (cider-nrepl-sync-request:eval form)
    (kill-region beg end)
    (cider-interactive-eval
     (ck/+clojure-pprint-expr form)
     (ck/cider-eval-read-and-print-handler))))

(defun ck/cider-eval-current-sexp-and-replace ()
  "Evaluate the expression at point and replace it with its result"
  (interactive)
  (apply #'ck/cider-eval-and-replace (cider-sexp-at-point 'bounds)))

(defun ck/cider-rejack ()
  "Jack back in!"
  (interactive)
  (sesman-quit)
  (cider-jack-in-clj&cljs))

(defun ck/clj-narrow-defun ()
  "Narrows to the current defun"
  (interactive)
  (save-mark-and-excursion
    (mark-defun)
    (call-interactively 'ck/narrow-and-zoom-in)))

(defun ck/clj-inspect-at-point ()
  "Open the current point in the cider inspector"
  (interactive)
  (save-excursion
    (goto-char (cadr (cider-sexp-at-point 'bounds)))
    (call-interactively #'cider-inspect)))

(defun ck/cider-unalias-at-point ()
  "Call (ns-unalias *ns* \\='sym) in the current Clojure namespace.
Uses the symbol at point as sym."
  (interactive)
  (let* ((sym (thing-at-point 'symbol t)))
    (if sym
        (let ((code (format "(ns-unalias *ns* '%s)" sym)))
          (cider-interactive-eval code))
      (message "No symbol at point."))))

(provide 'config/langs/clj/eval)

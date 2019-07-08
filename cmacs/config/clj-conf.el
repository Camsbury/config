(use-package bindings-conf)
(use-package evil)
(use-package lisp-conf)

(general-add-hook 'clojure-mode-hook
                  (list 'paredit-mode
                        'paxedit-mode
                        'format-all-mode
                        'smartparens-mode
                        'evil-smartparens-mode))

(general-add-hook 'before-save-hook
                  (lambda ()
                    (when (eq major-mode 'clojure-mode)
                      (delete-trailing-whitespace))))

(general-add-hook 'clojurescript-mode-hook
                  (list 'paredit-mode
                        'paxedit-mode
                        'format-all-mode
                        'smartparens-mode
                        'evil-smartparens-mode))

(general-add-hook 'before-save-hook
                  (lambda ()
                    (when (eq major-mode 'clojurescript-mode)
                      (delete-trailing-whitespace))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Functions

(defun cider-copy-last-result ()
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

(defun cider-insert-current-sexp-in-repl (&optional arg)
  "Insert the expression at point in the REPL buffer.
If invoked with a prefix ARG eval the expression after inserting it"
  (interactive "P")
  (cider-insert-in-repl (cider-sexp-at-point) arg))

(defun +clojure-pprint-expr (form)
  (format "(with-out-str (clojure.pprint/pprint %s))"
          form))

(defun cider-eval-read-and-print-handler (&optional buffer)
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

(defun cider-eval-and-replace (beg end)
  "Evaluate the expression in region and replace it with its result"
  (interactive "r")
  (let ((form (buffer-substring beg end)))
    (cider-nrepl-sync-request:eval form)
    (kill-region beg end)
    (cider-interactive-eval
     (+clojure-pprint-expr form)
     (cider-eval-read-and-print-handler))))

(defun cider-eval-current-sexp-and-replace ()
  "Evaluate the expression at point and replace it with its result"
  (interactive)
  (apply #'cider-eval-and-replace (cider-sexp-at-point 'bounds)))

(defun cider-rejack ()
  "Jack back in!"
  (interactive)
  (sesman-quit)
  (cider-jack-in-clj&cljs))

(defun clj-narrow-defun ()
  "Narrows to the current defun"
  (interactive)
  (save-mark-and-excursion
    (mark-defun)
    (call-interactively 'narrow-and-zoom-in)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Operators

(evil-define-operator fireplace-eval (beg end)
  (cider-interactive-eval nil nil (list beg end)))

(evil-define-operator fireplace-send (beg end)
  (cider-insert-current-sexp-in-repl nil nil (list beg end)))

(evil-define-operator fireplace-replace (beg end)
  (cider-eval-and-replace beg end))

(evil-define-operator fireplace-eval-context (beg end)
  (cider--eval-in-context (buffer-substring beg end)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bindings

(general-def 'normal clojure-mode-map
 "M-o" #'hydra-clj/body
 [remap empty-mode-leader]    #'hydra-clj/body
 [remap evil-lookup]          #'cider-doc
 [remap evil-goto-definition] #'cider-find-dwim
 [remap cider-inspector-pop]  #'paredit-backward)

(general-define-key :keymaps 'clojure-mode-map
  [remap paredit-raise-sexp] #'cljr-raise-sexp)

(defhydra hydra-clj (:exit t)
  "clojure-mode"
  ("d" #'cider-doc                   "documentation")
  ("D" #'cider-find-dwim             "jump to def")
  ("e" #'cider-inspect-last-result   "inspect last result")
  ("l" #'cider-load-buffer           "load buffer")
  ("n" #'cider-eval-ns-form          "eval ns")
  ("o" #'clj-narrow-defun            "focus on def")
  ("j" #'hydra-clj-jack-in/body         "hydra cider-jack-in")
  ("t" #'cider-switch-to-repl-buffer "repl")
  ("y" #'cider-copy-last-result      "copy last result"))
; cider-browse-spec
; cider-switch-to-repl-buffer
; clojure-move-to-let
; clojure-introduce-let
; cljr-add-require-to-ns

(defhydra hydra-clj-jack-in (:exit t)
  "cider-jack-in"
  ("q" #'sesman-quit            "Quit cider session")
  ("j" #'cider-jack-in-clj      "Jack in clj")
  ("s" #'cider-jack-in-cljs     "Jack in cljs")
  ("b" #'cider-jack-in-clj&cljs "Jack in both"))

;;; fireplace-esque eval binding
(nmap :keymaps 'cider-mode-map
  "c" (general-key-dispatch 'evil-change
        "p" (general-key-dispatch 'fireplace-eval
              "p" 'cider-eval-sexp-at-point
              "c" 'cider-eval-last-sexp
              "d" 'cider-eval-defun-at-point
              "r" 'cider-test-run-test)
        "q" (general-key-dispatch 'fireplace-send
              "q" 'cider-insert-current-sexp-in-repl
              "c" 'cider-insert-last-sexp-in-repl)
        "x" (general-key-dispatch 'fireplace-eval-context
              "x" 'cider-eval-sexp-at-point-in-context
              "c" 'cider-eval-last-sexp-in-context)
        "!" (general-key-dispatch 'fireplace-replace
              "!" 'cider-eval-current-sexp-and-replace
              "c" 'cider-eval-last-sexp-and-replace)))

(nmap :states 'normal :keymaps 'cider-mode-map
  "<RET>"   #'cider-inspector-operate-on-point
  "M-k"     #'cider-inspector-pop
  "M-<RET>" #'cider-eval-sexp-at-point)

(provide 'clj-conf)

(require 'config/langs/lisp)
(use-package clojure-mode
  :mode (("\\.clj\\'" . clojure-mode)
         ("\\.cljc\\'" . clojurec-mode)
         ("\\.cljs\\'" . clojurescript-mode)))
(use-package clj-refactor
  :after (clojure-mode))
(use-package flycheck-clj-kondo
  :after (clojure-mode))
(use-package cider
  :after (clojure-mode)
  :config
  (setq cider-clojure-cli-aliases "global"))
(use-package ivy-cider
  :after (clojure-mode))
(use-package ivy-clojuredocs
  :after (clojure-mode))
(use-package datomic-snippets
  :after (clojure-mode))
(use-package re-jump
  :after (clojure-mode))
(use-package html-to-hiccup)
(use-package clojars)
(use-package kaocha-runner)

(use-package clojure-essential-ref-nov
  :init
  (setq clojure-essential-ref-default-browse-fn
        #'clojure-essential-ref-nov-browse
        clojure-essential-ref-nov-epub-path
        "~/Dropbox/lxndr/books/Clojure_The_Essential_Reference_v29.epub"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup

(-map
 (lambda (mode)
   (general-add-hook
    mode
    (list 'paredit-mode
          'lispyville-mode
          'flycheck-mode)))
 '(clojure-mode-hook
   clojurec-mode-hook
   clojurescript-mode-hook))

(setq cider-repl-display-help-banner nil)
(setq cljr-warn-on-eval nil)
(setq cider-auto-select-error-buffer nil)

(general-add-hook
 'clojurescript-mode-hook
 (lambda ()
   (add-to-list 'imenu-generic-expression
                '("Spec" "s/def[[:blank:]\n]+:+\\(.*\\)" 1))
   (add-to-list 'imenu-generic-expression
                '("Effect" "reg-fx[[:blank:]\n]+:+\\(.*\\)" 1))
   (add-to-list 'imenu-generic-expression
                '("Coeffect" "reg-cofx[[:blank:]\n]+:+\\(.*\\)" 1))
   (add-to-list 'imenu-generic-expression
                '("Event" "reg-event-\\(db\\|fx\\)[[:blank:]\n]+:+\\(.*\\)" 2))
   (add-to-list 'imenu-generic-expression
                '("Sub" "reg-sub[[:blank:]\n]+:+\\(.*\\)" 1))))


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
  [remap empty-mode-leader]    #'hydra-clj/body
  [remap evil-goto-definition] (lambda ()
                                 (interactive)
                                 (cider-find-var (point)))
  [remap dumb-jump-go] (lambda ()
                         (interactive)
                         (cider-doc (point)))
  [remap cider-inspector-pop]  #'evil-previous-visual-line
  "M-<RET>" #'cider-eval-sexp-at-point
  ;; USEIT
  "M-n"     #'clojure-unwind-all
  "M-e"     #'clojure-thread-first-all
  "M-i"     #'clojure-thread-last-all)

(general-define-key :keymaps 'clojure-mode-map
  [remap paredit-raise-sexp] #'cljr-raise-sexp)

(defhydra hydra-clj (:exit t :columns 5)
  "clojure-mode"
  ("=" #'clojure-align                 "align")
  ("a" #'ivy-cider-apropos             "apropos")
  ("e" #'cljr-move-to-let              "move to let")
  ("f" #'cljr-find-usages              "find refs")
  ;; USEIT
  ("H" #'html-to-hiccup-convert-region "convert HTML to hiccup")
  ("j" #'hydra-clj-jack-in/body        "hydra cider-jack-in")
  ;; USEIT
  ("J" #'clojars                       "search in clojars")
  ("l" #'cider-load-buffer             "load buffer")
  ("m" #'hydra-cljr-help-menu/body     "cljr hydra")
  ("n" #'cljr-introduce-let            "introduce let")
  ("o" #'clj-narrow-defun              "focus on def")
  ("q" #'cljr-add-require-to-ns        "add require")
  ("t" #'cider-test-run-ns-tests       "run ns tests")
  ("T" #'kaocha-runner-run-all-tests   "run project tests")
  ("w" #'cljr-add-missing-libspec      "figure out the require")
  ("y" #'cider-copy-last-result        "copy last result"))

; clojure-thread-first-all
; clojure-thread-last-all
; clojure-unwind-all
; clojure-cycle-privacy
; cljr-cycle-thread
; clojure-convert-collection-to...
; cljr-rename-file-or-dir
; cljr-rename-file
; cljr-move-form
; cljr-add-declaration
; cljr-extract-constant
; cljr-extract-def
; cljr-expand-let --- HUGE
; cljr-remove-let
; cljr-add-project-dependency
; cljr-update-project-dependency
; cljr-promote-function
; cljr-rename-symbol
; cljr-clean-ns
; cljr-add-missing-libspec
; cljr-extract-function
; cljr-add-stubs
; cljr-inline-symbol

(defhydra hydra-clj-jack-in (:exit t)
  "cider-jack-in"
  ("q" #'sesman-quit            "Quit cider session")
  ("r" #'sesman-restart         "Restart cider session")
  ("c" #'cider-connect          "Connect to running nREPL")
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
  ;; "M-k"     #'cider-inspector-pop
  "M-<RET>" #'cider-eval-sexp-at-point
  "gh"     #'hydra-clj/hydra-cljr-help-menu/body)

(general-define-key :keymaps 'cider-repl-mode-map
  "M-l" #'cider-repl-clear-buffer)

(provide 'config/langs/clj)

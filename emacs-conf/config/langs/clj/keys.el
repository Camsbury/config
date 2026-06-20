;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'config/langs/clj/eval)
(require 'config/langs/clj/jack-in)
(require 'config/langs/clj/systemic)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Operators

(evil-define-operator fireplace-eval (beg end)
  (cider-interactive-eval nil nil (list beg end)))

(evil-define-operator fireplace-send (beg end)
  (ck/cider-insert-current-sexp-in-repl nil nil (list beg end)))

(evil-define-operator fireplace-replace (beg end)
  (ck/cider-eval-and-replace beg end))

(evil-define-operator fireplace-eval-context (beg end)
  (cider--eval-in-context (buffer-substring beg end)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bindings

;; NOTE: was a pain to get this working, but makes some sense, would rather not
;; have to choose between the two (non-overlapping keys)

;; 0) Load the map (it's not autoloaded)
(with-eval-after-load 'cider-debug
  ;; 1) Make the CIDER debug minor-mode map override Evil's state maps
  (evil-make-overriding-map cider--debug-mode-map 'normal 'motion)
  ;; 2) Recompute keymaps when the debug mode toggles, so overriding takes effect
  (add-hook 'cider--debug-mode-hook #'evil-normalize-keymaps)

  ;; 3) Bind with Evil’s higher-precedence API
  (evil-define-key* '(normal motion) cider--debug-mode-map
    "n" (lambda ()
          (interactive)
          (cider-debug-mode-send-reply ":next"))
    "o" (lambda ()
          (interactive)
          (cider-debug-mode-send-reply ":out"))
    "c" (lambda ()
          (interactive)
          (cider-debug-mode-send-reply ":continue"))
    "e" (lambda ()
          (interactive)
          (cider-debug-mode-send-reply ":eval"))
    "p" (lambda ()
          (interactive)
          (cider-debug-mode-send-reply ":inspect"))
    "h" (lambda ()
          (interactive)
          (cider-debug-mode-send-reply ":here"))
    "l" (lambda ()
          (interactive)
          (cider-debug-mode-send-reply ":locals"))
    "q" (lambda ()
          (interactive)
          (cider-debug-mode-send-reply ":quit"))))

(general-def 'normal clojure-mode-map
  [remap ck/empty-mode-leader]     #'hydra-clj/body
  [remap evil-goto-definition] (lambda ()
                                 (interactive)
                                 (call-interactively #'cider-find-var))
  [remap dumb-jump-go] (lambda ()
                         (interactive)
                         (call-interactively #'cider-doc))
  [remap cider-inspector-pop]  #'evil-previous-visual-line
  "M-<RET>" #'cider-eval-sexp-at-point
  "C-<return>" #'cider-eval-last-sexp
  "M-n"     #'clojure-unwind-all
  "M-e"     #'clojure-thread-first-all
  "M-i"     #'clojure-thread-last-all
  "M-y"     #'ck/clj-inspect-at-point
  "M-o"     #'cider-inspect-last-result)

(general-def 'normal cider-inspector-mode-map
  "M-<RET>" #'cider-inspector-operate-on-point
  "M-k"     #'cider-inspector-previous-inspectable-object
  "M-j"     #'cider-inspector-next-inspectable-object
  "M-l"     #'cider-inspector-operate-on-point
  "M-L"     #'cider-inspector-next-page
  "M-H"     #'cider-inspector-prev-page
  "M-h"     #'cider-inspector-pop)

(general-define-key :keymaps 'clojure-mode-map
                    [remap paredit-raise-sexp] #'cljr-raise-sexp)

(defhydra hydra-clj (:exit t :columns 5)
  "clojure-mode"
  ("=" #'clojure-align                    "align")
  ("c" #'cider-clojuredocs                "cider clojuredocs")
  ("d" #'cider-debug-defun-at-point       "debug at point")
  ("e" #'cljr-move-to-let                 "move to let")
  ("f" #'cljr-find-usages                 "find refs")
  ;; USEIT
  ("H" #'html-to-hiccup-convert-region    "convert HTML to hiccup")
  ("j" #'hydra-clj-jack-in/body           "hydra cider-jack-in")
  ;; USEIT
  ("J" #'clojars                          "search in clojars")
  ("l" #'cider-load-buffer                "load buffer")
  ("m" #'hydra-cljr-help-menu/body        "cljr hydra")
  ("M" #'hydra-systemic/body              "systemic hydra")
  ("n" #'cljr-introduce-let               "introduce let")
  ("N" #'clojure-sort-ns                  "sort ns")
  ("o" #'ck/clj-narrow-defun                 "focus on def")
  ("p" #'cider-eval-defun-at-point        "eval outer sexp")
  ("q" #'cljr-add-require-to-ns           "add require")
  ("r" #'clojure-essential-ref            "lookup in essential ref")
  ("s" #'ck/clerk-show                       "show clerk notebook")
  ("S" #'ck/clerk-show-tap                   "show clerk notebook")
  ("t" #'cider-test-run-ns-tests          "run ns tests")
  ("T" #'kaocha-runner-run-all-tests      "run project tests")
  ("u" #'ck/cider-unalias-at-point           "unalias the symbol at point")
  ("w" #'cljr-add-missing-libspec         "figure out the require")
  ("y" #'ck/cider-copy-last-result           "copy last result")
  ("Y" #'ck/cider-copy-last-result-dwim      "copy last result dwim")

  ("s-t" #'ck/systemic-start-system-at-point   "Start systemic system")
  ("s-s" #'ck/systemic-stop-system-at-point    "Stop systemic system")
  ("s-r" #'ck/systemic-restart-system-at-point "Retart systemic system")
  ("s-T" #'ck/systemic-start                   "Start systemic systems")
  ("s-S" #'ck/systemic-stop                    "Stop systemic systems")
  ("s-R" #'ck/systemic-restart                 "Retart systemic systems"))

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
  ;; ("q" #'sesman-quit         "Quit cider session")
  ("q" #'ck/cider-kill-tmux     "Quit cider session")
  ("r" #'sesman-restart         "Restart cider session")
  ("c" #'cider-connect          "Connect to running nREPL")
  ("j" #'ck/cider-jack-in-tmux  "Jack in clj via tmux")
  ;; ("j" #'cider-jack-in-clj   "Jack in clj")
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
              "q" 'ck/cider-insert-current-sexp-in-repl
              "c" 'cider-insert-last-sexp-in-repl)
        "x" (general-key-dispatch 'fireplace-eval-context
              "x" 'cider-eval-sexp-at-point-in-context
              "c" 'cider-eval-last-sexp-in-context)
        "!" (general-key-dispatch 'fireplace-replace
              "!" 'ck/cider-eval-current-sexp-and-replace
              "c" 'cider-eval-last-sexp-and-replace)))

(nmap :states 'normal :keymaps 'cider-mode-map
  "<RET>"   #'cider-inspector-operate-on-point
  ;; "M-k"     #'cider-inspector-pop
  "M-<RET>" #'cider-eval-sexp-at-point
  "gh"     #'hydra-clj/hydra-cljr-help-menu/body)

(general-define-key :keymaps 'cider-repl-mode-map
  "M-l" #'cider-repl-clear-buffer)

(provide 'config/langs/clj/keys)

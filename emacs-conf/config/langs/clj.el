;;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'config/langs/lisp)

;; cmacs-share-path is a core/env global (loaded at boot before config); the
;; clojure-essential-ref epub path builds on it.  Declare rather than require
;; core/env so we do not force-load a cross-area module.
(declare-vars cmacs-share-path)

(use-package clojure-mode
  :mode (("\\.bb\\'" . clojure-mode)
         ("\\.clj\\'" . clojure-mode)
         ("\\.cljc\\'" . clojurec-mode)
         ("\\.cljs\\'" . clojurescript-mode)))
(use-package clj-refactor
  :after clojure-mode
  :hook (clojure-mode . clj-refactor-mode)
  :config
  ;; prevent firing the missiles in some projects
  (setq cljr-eagerly-build-asts-on-startup nil)
  ;; (setq cljr-warn-on-eval nil) ;; turned off for the above
  ;; setup some extra namespace auto completion for great awesome
  (dolist (mapping '(("re-frame" . "re-frame.core")
                     ("reagent"  . "reagent.core")
                     ("str"      . "clojure.string")))
    (add-to-list 'cljr-magic-require-namespaces mapping t)))
(use-package flycheck-clj-kondo
  :after (clojure-mode))
(use-package cider
  :after (clojure-mode))
(use-package ivy-clojuredocs
  :after (clojure-mode))
(use-package datomic-snippets
  :after (clojure-mode))
(use-package html-to-hiccup)
(use-package clojars)
(use-package kaocha-runner)

(use-package clojure-essential-ref-nov
  :init
  (setq clojure-essential-ref-default-browse-fn
        #'clojure-essential-ref-nov-browse
        clojure-essential-ref-nov-epub-path
        (concat cmacs-share-path
                "/books/Clojure_The_Essential_Reference.epub")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup

(setq cider-clojure-compilation-error-phases nil)

(setq clojure-toplevel-inside-comment-form t)

(-each
 '(clojure-mode-hook
   clojurec-mode-hook
   clojurescript-mode-hook)
 (lambda (mode)
   (general-add-hook
    mode
    (list 'paredit-mode
          'lispyville-mode
          'flycheck-mode))))

(setq cider-repl-display-help-banner nil)
(setq cider-auto-select-error-buffer nil)
(setq clojure-align-forms-automatically t)

;; systemic nice to haves
(put 'defsys 'clojure-doc-string-elt 2)

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
;; Indentation

(setq clojure-indent-style 'align-arguments)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Child modules: eval ops, tmux jack-in, systemic, bindings/hydras

(m-require config/langs/clj
  eval
  jack-in
  systemic
  keys)

(provide 'config/langs/clj)

;; use-package config file: the "undefined" symbols are the packages' own
;; config APIs (clojure-mode, clj-refactor, cider, general).  Suppress only
;; the unresolved class; keep every other warning live.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

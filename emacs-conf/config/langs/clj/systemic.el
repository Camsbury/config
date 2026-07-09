;; -*- lexical-binding: t; -*-
(require 'prelude)

;; CIDER loads lazily with clojure-mode; every use below is inside an
;; interactive defun, so forward-declare rather than force-load CIDER.
(declare-functions "cider-eval" cider-interactive-eval)
(declare-functions "cider-util" cider-sexp-at-point)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Systemic

(defun ck/systemic-restart ()
  "Restarts systemic"
  (interactive)
  (cider-interactive-eval "(systemic.core/restart!)"))

(defun ck/systemic-start ()
  "Starts systemic"
  (interactive)
  (cider-interactive-eval "(systemic.core/start!)"))

(defun ck/systemic-stop ()
  "Stops systemic"
  (interactive)
  (cider-interactive-eval "(systemic.core/stop!)"))

(defun ck/systemic-start-system-at-point ()
  "Starts systemic system"
  (interactive)
  (cider-interactive-eval (concat "(systemic.core/start! `" (cider-sexp-at-point) ")")))

(defun ck/systemic-stop-system-at-point ()
  "Stops systemic system"
  (interactive)
  (cider-interactive-eval (concat "(systemic.core/stop! `" (cider-sexp-at-point) ")")))

(defun ck/systemic-restart-system-at-point ()
  "Restarts systemic system"
  (interactive)
  (cider-interactive-eval (concat "(systemic.core/restart! `" (cider-sexp-at-point) ")")))

(provide 'config/langs/clj/systemic)

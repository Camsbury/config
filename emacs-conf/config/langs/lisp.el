;; -*- lexical-binding: t; -*-
(require 'prelude)
;; general (+ general-evil-setup) and hydra macros come from here.  This file
;; references no core/bindings hub symbols, so requiring the foundation instead
;; of the hub removes the hub edge entirely.
(require 'core/definers)
(require 'lib/utils)   ; ck/lisp-eval-sexp-at-point
(use-package paredit)
(use-package lispyville)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Hooks

(general-add-hook 'lisp-interaction-mode-hook
                  (list 'paredit-mode
                        'lispyville-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Functions

; straight outta smartparens
(defun ck/sp-forward-whitespace (&optional arg)
  "Skip forward past the whitespace characters.
With non-nil ARG return number of characters skipped."
  (interactive "^P")
  (let ((rel-move (skip-chars-forward " \t\n")))
    (if arg rel-move (point))))

(defun ck/lisp-tree-forward ()
  "Move forward in the lisp tree"
  (interactive)
  (paredit-forward)
  (when (or (= 32 (following-char)) (= 10 (following-char)))
    (ck/sp-forward-whitespace)))

(defun ck/lisp-tree-last ()
  "Move to the last element of the list"
  (interactive)
  (paredit-backward-up)
  (paredit-forward)
  (paredit-backward-down))

(defun ck/lisp-open-above ()
  "Open above the current list"
  (interactive)
  (if (= 40 (following-char))
      (progn
        (call-interactively #'paredit-forward-down)
        (call-interactively #'lispyville-open-above-list))
    (call-interactively #'lispyville-open-above-list)))

;; `ck/lisp-eval-sexp-at-point' used to live here; it is consumed across
;; areas (lib/shell's `ck/run-async-from-desc', the binding below), so it
;; moved to lib/utils.el.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Bindings

(general-evil-define-key 'normal 'paredit-mode-map
  "h"    #'evil-backward-char
  "j"    #'evil-next-visual-line
  "k"    #'evil-previous-visual-line
  "l"    #'evil-forward-char

  ;; "I"   #'lispyville-insert-at-beginning-of-list
  ;; "A"   #'lispyville-insert-at-end-of-list

  ;; "o"   #'lispyville-open-below-list
  ;; "O"   #'ck/lisp-open-above
  )

(general-define-key :keymaps 'paredit-mode-map
  "C-h"     #'evil-window-left
  "C-j"     #'evil-window-down
  "C-k"     #'evil-window-up
  "C-l"     #'evil-window-right

  "M-h"     #'paredit-backward-up
  "M-j"     #'ck/lisp-tree-forward
  "M-k"     #'paredit-backward
  "M-l"     #'paredit-forward-down

  "M-o"     #'evil-open-below
  "M-O"     #'evil-open-above

  "M-L"     #'ck/lisp-tree-last
  "M-H"     #'lispy-raise-sexp

  "M-s"     #'paredit-forward-slurp-sexp
  "M-t"     #'paredit-forward-barf-sexp
  "M-a"     #'paredit-backward-barf-sexp
  "M-r"     #'paredit-backward-slurp-sexp

  "M-f"     #'lispyville-drag-backward
  "M-p"     #'lispyville-drag-forward
  "M-<RET>" #'ck/lisp-eval-sexp-at-point)



(provide 'config/langs/lisp)

;; use-package config + keybinding file: the "undefined" symbols are paredit /
;; lispyville / evil / cider commands invoked only at runtime.  Suppress the
;; unresolved class; keep every other class live.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

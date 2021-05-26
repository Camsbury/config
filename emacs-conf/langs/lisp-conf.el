(use-package paredit)
(use-package lispyville)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Hooks

(general-add-hook 'lisp-interaction-mode-hook
                  (list 'paredit-mode
                        'lispyville-mode))
(with-current-buffer "*scratch*"
  (call-interactively #'lisp-interaction-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Functions

; straight outta smartparens
(defun sp-forward-whitespace (&optional arg)
  "Skip forward past the whitespace characters.
With non-nil ARG return number of characters skipped."
  (interactive "^P")
  (let ((rel-move (skip-chars-forward " \t\n")))
    (if arg rel-move (point))))

(defun lisp-tree-forward ()
  "Move forward in the lisp tree"
  (interactive)
  (paredit-forward)
  (when (or (= 32 (following-char)) (= 10 (following-char)))
    (sp-forward-whitespace)))

(defun lisp-tree-last ()
  "Move to the last element of the list"
  (interactive)
  (paredit-backward-up)
  (paredit-forward)
  (paredit-backward-down))

(defun lisp-open-above ()
  "Open above the current list"
  (interactive)
  (if (= 40 (following-char))
      (progn
        (call-interactively #'paredit-forward-down)
        (call-interactively #'lispyville-open-above-list))
    (call-interactively #'lispyville-open-above-list)))


(defun lisp-eval-sexp-at-point ()
  "Evaluate the expression around point, like CIDER does."
  (interactive)
  (save-excursion
    (goto-char (cadr (cider-sexp-at-point 'bounds)))
    (call-interactively #'eval-last-sexp)))


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
  ;; "O"   #'lisp-open-above
  )

(general-define-key :keymaps 'paredit-mode-map
  "C-h"     #'evil-window-left
  "C-j"     #'evil-window-down
  "C-k"     #'evil-window-up
  "C-l"     #'evil-window-right

  "M-h"     #'paredit-backward-up
  "M-j"     #'lisp-tree-forward
  "M-k"     #'paredit-backward
  "M-l"     #'paredit-forward-down

  "M-o"     #'evil-open-below
  "M-O"     #'evil-open-above

  "M-L"     #'lisp-tree-last
  "M-H"     #'lispy-raise-sexp

  "M-s"     #'paredit-forward-slurp-sexp
  "M-t"     #'paredit-forward-barf-sexp
  "M-a"     #'paredit-backward-barf-sexp
  "M-r"     #'paredit-backward-slurp-sexp

  "M-f"     #'lispyville-drag-backward
  "M-p"     #'lispyville-drag-forward
  "M-<RET>" #'lisp-eval-sexp-at-point)



(provide 'langs/lisp-conf)

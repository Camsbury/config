(require 'bindings-conf)
(require 'paxedit)

(general-evil-define-key 'normal lisp-interaction-mode-map
  [remap eval-print-last-sexp] 'evil-window-down)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Paxedit movement functions

(defmacro define-move-and-insert
    (name &rest body)
  `(defun ,name (count &optional vcount skip-empty-lines)
     ;; Following interactive form taken from the source for `evil-insert'
     (interactive
      (list (prefix-numeric-value current-prefix-arg)
            (and (evil-visual-state-p)
                 (memq (evil-visual-type) '(line block))
                 (save-excursion
                   (let ((m (mark)))
                     ;; go to upper-left corner temporarily so
                     ;; `count-lines' yields accurate results
                     (evil-visual-rotate 'upper-left)
                     (prog1 (count-lines evil-visual-beginning evil-visual-end)
                       (set-mark m)))))
            (evil-visual-state-p)))
     (atomic-change-group
       ,@body
       (evil-insert count vcount skip-empty-lines))))

(define-move-and-insert grfn/insert-at-sexp-end
  (when (not (equal (get-char) "("))
    (backward-up-list))
  (forward-sexp)
  (backward-char))

(define-move-and-insert grfn/insert-at-sexp-start
  (backward-up-list)
  (forward-char))

(define-move-and-insert grfn/insert-at-form-start
  (backward-sexp)
  (backward-char)
  (insert " "))

(define-move-and-insert grfn/insert-at-form-end
  (forward-sexp)
  (insert " "))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Paxedit mappings

(general-define-key :keymaps 'paredit-mode-map
  "C-h" #'evil-window-left
  "C-j" #'evil-window-down
  "C-k" #'evil-window-up
  "C-l" #'evil-window-right
  "M-t" #'paredit-forward
  "M-p" #'paredit-forward-up
  "M-v" #'paredit-forward-down
  "M-a" #'paredit-backward
  "M-q" #'paredit-backward-up
  "M-z" #'paredit-backward-down
  "M-r" #'sp-forward-slurp-sexp
  "M-s" #'sp-forward-barf-sexp
  "M-w" #'sp-backward-barf-sexp
  "M-f" #'sp-backward-slurp-sexp
  [remap evil-multiedit-match-symbol-and-next] #'paxedit-transpose-forward
  "M-b" #'paxedit-transpose-backward
  )

(provide 'lisp-conf)

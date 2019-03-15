(require 'bindings-conf)
(require 'paxedit)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Lisp Functions

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

(defun lisp-tree-forward ()
  (interactive)
  "Move forward in the lisp tree"
  (paredit-forward)
  (when (and
         (/= ?} (following-char))
         (/= ?\) (following-char))
         (/= ?\] (following-char)))
    (sp-next-sexp)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Paxedit mappings

(general-evil-define-key 'normal lisp-interaction-mode-map
  [remap eval-print-last-sexp] 'evil-window-down)

(general-define-key :keymaps 'paredit-mode-map
  "C-h" #'evil-window-left
  "C-j" #'evil-window-down
  "C-k" #'evil-window-up
  "C-l" #'evil-window-right

  "M-j" #'lisp-tree-forward
  "M-l" #'paredit-forward-down
  "M-k" #'paredit-backward
  "M-h" #'paredit-backward-up
  "M-H" #'paredit-raise-sexp

  "M-s" #'paredit-forward-slurp-sexp
  "M-t" #'paredit-forward-barf-sexp
  "M-a" #'paredit-backward-barf-sexp
  "M-r" #'paredit-backward-slurp-sexp

  "M-f" #'paxedit-transpose-backward
  "M-p" #'paxedit-transpose-forward)

(general-evil-define-key 'normal paredit-mode-map
  "B"       #'sp-backward-symbol
  "W"       #'paxedit-next-symbol
  "M-<RET>" #'eval-defun)

(provide 'lisp-conf)

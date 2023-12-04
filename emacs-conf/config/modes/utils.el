(defun minor-mode-active-p (minor-mode)
  "Check if the passed minor-mode is active"
  (->> minor-mode-list
    (--filter
     (and
      (boundp it)
      (symbol-value it)))
    (--filter
     (eq it minor-mode))
    null
    not))

(provide 'config/modes/utils)

(defun minor-mode-active-p (minor-mode)
  "Check if the passed minor-mode is active"
  (not
   (null
    (--filter
     (eq it minor-mode)
     (--filter
      (and
       (boundp it)
       (symbol-value it))
      minor-mode-list)))))

(provide 'config/modes/utils)

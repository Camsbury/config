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

(defun unescape-clipboard-string ()
  "Unescape the current clipboard string and replace it back onto the clipboard."
  (interactive)
  (let ((current-clipboard (current-kill 0 t)))
    (kill-new (read current-clipboard))))

(provide 'config/modes/utils)

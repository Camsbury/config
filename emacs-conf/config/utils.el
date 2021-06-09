(defun random-uuid ()
  "Returns a random UUID V4"
  (interactive)
  (kill-new (uuidgen-4)))

(defun file-to-string (file-name)
  (with-temp-buffer
    (insert-file-contents file-name)
    (buffer-string)))

(provide 'config/utils)

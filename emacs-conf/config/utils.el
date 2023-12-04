(defun random-uuid ()
  "Returns a random UUID V4"
  (interactive)
  (kill-new (uuidgen-4)))

(defun file-to-string (file-name)
  (with-temp-buffer
    (insert-file-contents file-name)
    (buffer-string)))

(defun delete-file-and-buffer ()
  "Kill the current buffer and deletes the file it is visiting."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if filename
        (if (y-or-n-p (concat "Do you really want to delete file " filename " ?"))
            (progn
              (delete-file filename)
              (message "Deleted file %s." filename)
              (kill-buffer)))
      (message "Not a file visiting buffer!"))))

(defun shuffle-selection (beginning end)
  "Shuffle the current selection"
  (interactive "r")
  (shell-command-on-region beginning end "shuf" nil t))

(defun unescape-clipboard-string ()
  "Unescape the current clipboard string and replace it back onto the clipboard."
  (interactive)
  (let ((current-clipboard (current-kill 0 t)))
    (kill-new (read current-clipboard))))

(provide 'config/utils)

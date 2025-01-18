(require 'prelude)
(require 'config/modes/utils)

(defface breeze-face
  '((t :foreground "#d074e8" :height 1.1))
  "Face for bolding the first letter of each word"
  :group 'breeze)

(defvar breeze-font-lock-keywords
  '(("\\b\\(\\w\\)" 1 'breeze-face prepend))
  "Font-lock keywords for `breeze-mode`.")

;;;###autoload
(define-derived-mode breeze-mode fundamental-mode "Breeze"
  "A major mode that bolds the first letter of each word."
  (setq font-lock-defaults '(breeze-font-lock-keywords))
  (font-lock-mode 1))

(defun breeze-paste-from-clipboard ()
  "Create a new buffer, paste clipboard text into it, and enable `breeze-mode`."
  (interactive)
  (let ((clipboard-text (gui-get-selection 'CLIPBOARD)))
    (if clipboard-text
        (let* ((name "*Breeze Clipboard*")
               (buffers (-map #'buffer-name (buffer-list)))
               (match (-first (lambda (buffer) (s-match name buffer)) buffers)))
          (if match
              (switch-to-buffer name)
            (switch-to-buffer (generate-new-buffer name)))
          (erase-buffer)
          (insert clipboard-text)
          (breeze-mode)
          (setq-local face-remapping-alist
                      '((default :height 2.0)))
          (font-lock-ensure))  ; Ensure font-lock is applied
      (message "Clipboard is empty"))))

(provide 'config/modes/breeze-mode)

(define-minor-mode prettify-mode
  "Make buffers clean themselves up if this mode is on"
  :lighter " prettify"
  :global nil
  :after-hook
  (if (minor-mode-active-p 'prettify-mode)
      (message "prettify-mode-enabled")
    (message "prettify-mode-disabled")))

(defun prettify-windows ()
  "Set the windows all to have 81 chars of length"
  (interactive)
  (save-selected-window
    (select-window (frame-first-window))
    (while (window-next-sibling)
      (when (minor-mode-active-p 'prettify-mode)
        (set-window-width 85))
      (select-window (window-next-sibling)))))


(provide 'modes/prettify-mode)

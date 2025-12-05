(defvar center-buffer-width nil
  "Width of the centered text area. If nil, use `fill-column'.")

(define-minor-mode center-buffer-mode
  "Center a fixed-width text column without changing wrapping."
  :init-value nil
  :lighter " ⊣⊢"
  (if center-buffer-mode
      (progn
        ;; React to changes in window layout / size
        (add-hook 'window-configuration-change-hook #'center-buffer-adjust nil t)
        (when (boundp 'window-state-change-functions)
          (add-hook 'window-state-change-functions #'center-buffer-adjust nil t))
        (center-buffer-adjust))
    (remove-hook 'window-configuration-change-hook #'center-buffer-adjust t)
    (when (boundp 'window-state-change-functions)
      (remove-hook 'window-state-change-functions #'center-buffer-adjust t))
    ;; Reset margins when disabling
    (set-window-margins (selected-window) 0 0)))

(defun center-buffer-adjust (&optional _arg)
  "Recompute margins to center `fill-column` (or `center-buffer-width`).

  If the current buffer's window is no longer the only window on its
  frame, disable `center-buffer-mode` in this buffer."
  (when center-buffer-mode
    (let* ((win   (get-buffer-window (current-buffer) 'visible)))
      (when (window-live-p win)
        (let* ((target-width (or center-buffer-width fill-column))
               (pad (max 0 (/ (- (frame-width) target-width) 2))))
          (unless (eq major-mode 'exwm-mode)
            (set-window-margins win pad)))))))

(defun center-buffer--disable-before-split (&rest _)
  "Disable centering in this buffer if active before a split."
  (when center-buffer-mode
    (center-buffer-mode -1)))

;; Advice the standard split commands
(dolist (fn '(split-window-right split-window-below))
  (advice-add fn :before #'center-buffer--disable-before-split))

(defun center-buffer--center-when-single ()
  "Turn on when single window in the frame"
  (interactive)
  (let* ((win   (get-buffer-window (current-buffer) 'visible))
         (num-windows
          (length (window-list (window-frame win) 'no-mini))))
    (unless (> num-windows 1)
      (center-buffer-mode 1))))

(provide 'config/modes/center-buffer-mode)

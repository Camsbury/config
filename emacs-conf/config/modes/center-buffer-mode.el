;; -*- lexical-binding: t; -*-
(defun center-buffer--pad-modeline ()
  "Add left modeline padding equal to window left margin."
  (let* ((margins (window-margins))
         (left (or (car margins) 0)))
    (propertize " " 'display `(space :width ,left))))

(defun center-buffer-enable-modeline-padding ()
  (interactive)
  (setq-local
   mode-line-format
   (cons '(:eval (center-buffer--pad-modeline))
         mode-line-format)))

(defun center-buffer-disable-modeline-padding  ()
  (interactive)
  (kill-local-variable 'mode-line-format))

(defvar center-buffer-width nil
  "Width of the centered text area. If nil, use `fill-column'.")

(define-minor-mode center-buffer-mode
  "Center a fixed-width text column without changing wrapping.

Never activates in EXWM buffers: managing margins and modeline
padding on an X window does weird things, so the mode refuses to
turn on there no matter who enabled it."
  :init-value nil
  :lighter " ⊣⊢"
  (cond
   ;; Hard refusal: bail out cleanly if something tried to enable us in
   ;; an EXWM buffer.
   ((and center-buffer-mode (derived-mode-p 'exwm-mode))
    (setq center-buffer-mode nil))
   (center-buffer-mode
    ;; React to changes in window layout / size
    (add-hook 'window-configuration-change-hook #'center-buffer-adjust nil t)
    (when (boundp 'window-state-change-functions)
      (add-hook 'window-state-change-functions #'center-buffer-adjust nil t))
    (center-buffer-adjust)
    (center-buffer-enable-modeline-padding))
   (t
    (remove-hook 'window-configuration-change-hook #'center-buffer-adjust t)
    (when (boundp 'window-state-change-functions)
      (remove-hook 'window-state-change-functions #'center-buffer-adjust t))
    ;; Reset margins when disabling
    (set-window-margins (selected-window) 0 0)
    (center-buffer-disable-modeline-padding))))

(defun center-buffer-adjust (&optional _arg)
  "Recompute margins to center `fill-column` (or `center-buffer-width`).

  If the current buffer's window is no longer the only window on its
  frame, disable `center-buffer-mode` in this buffer.  Because this
  runs from `window-configuration-change-hook' /
  `window-state-change-functions', it self-disables no matter how the
  extra window appeared (interactive split, `display-buffer', eca,
  side windows, ...)."
  (when center-buffer-mode
    (let ((win (get-buffer-window (current-buffer) 'visible)))
      (when (window-live-p win)
        (if (> (length (window-list (window-frame win) 'no-mini)) 1)
            ;; No longer alone on the frame: stop centering entirely.
            (center-buffer-mode -1)
          (let* ((target-width (or center-buffer-width fill-column))
                 (pad (max 0 (/ (- (window-total-width win) target-width) 2))))
            (set-window-margins win pad)))))))

(defun center-buffer--center-when-single ()
  "Turn on when single window in the frame"
  (interactive)
  (let* ((win   (get-buffer-window (current-buffer) 'visible))
         (num-windows
          (length (window-list (window-frame win) 'no-mini))))
    (unless (> num-windows 1)
      (center-buffer-mode 1))))

(provide 'config/modes/center-buffer-mode)

(use-package buffer-move)

(defun windows-undedicate-workspace-buffer (dedicated-workspace)
  (interactive
   (list
    (exwm-workspace--prompt-for-workspace
     "Pick dedicated workspace [+/-]: ")))
  (-> dedicated-workspace
    exwm-workspace--workspace-from-frame-or-index
    frame-selected-window
    (set-window-dedicated-p nil)))

(defun windows-fix-broken-workspace (broken-workspace)
  "Place a new frame in the given frame/index, without affecting other frames"
  (interactive
   (list
    (exwm-workspace--prompt-for-workspace
     "Pick broken workspace [+/-]: ")))
  (let* ((current-index exwm-workspace-current-index)
         (default-limit exwm-workspace-switch-create-limit)
         (temp-limit (inc default-limit)))
    (customize-set-variable 'exwm-workspace-switch-create-limit temp-limit)
    (exwm-workspace-switch-create default-limit)
    (exwm-workspace-switch-create current-index)
    (exwm-workspace-swap
     (exwm-workspace--workspace-from-frame-or-index broken-workspace)
     (exwm-workspace--workspace-from-frame-or-index default-limit))
    (customize-set-variable 'exwm-workspace-switch-create-limit default-limit)))

(defun set-window-width (window count)
  "Set the selected window's width."
  (when (and (window-combined-p window t)
             (window-right window))
    (adjust-window-trailing-edge
     window
     (- count (window-width))
     t)))

;; EXWM manage windows
(setq exwm-manage-configurations '((t managed t)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; hooks

(defvar after-delete-window-hook nil
  "Functions run after a window is deleted")
(defun run-after-delete-window-hook (&rest _)
  (run-hooks 'after-delete-window-hook))
(advice-add #'delete-window :after #'run-after-delete-window-hook)

(defvar after-split-window-hook nil
  "Functions run after a window is split")
(defun run-after-split-window-hook (&rest _)
  (run-hooks 'after-split-window-hook))
(advice-add #'split-window :after #'run-after-split-window-hook)

(provide 'config/desktop/windows)

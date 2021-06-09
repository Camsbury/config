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

(defun set-window-width (count)
  "Set the selected window's width."
  (adjust-window-trailing-edge (selected-window) (- count (window-width)) t))

;; manage windows
(setq exwm-manage-configurations '((t managed t)))

(provide 'config/desktop/windows)

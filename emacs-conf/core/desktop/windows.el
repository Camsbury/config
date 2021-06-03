(defun global-exwm-key (key cmd)
  "bind key for use across all exwm buffers"
  (general-define-key :keymaps 'exwm-mode-map key cmd)
  (exwm-input-set-key (kbd key) cmd))

(use-package exwm
  :init
  (setq exwm-workspace-show-all-buffers t)
  (setq exwm-layout-show-all-buffers t))

(use-package exwm-config
  :after (exwm)
  :config
  (add-hook 'exwm-update-class-hook
            (lambda ()
              (exwm-workspace-rename-buffer exwm-class-name)))
  (setq exwm-workspace-number 10
        exwm-workspace-current-index 1
        exwm-input-global-keys
        `(([?\s-r] . exwm-reset)
          ([?\s-w] . exwm-workspace-switch)
          ,@(mapcar (lambda (i)
                      `(,(kbd (format "s-%d" i)) .
                        (lambda ()
                          (interactive)
                          (exwm-workspace-switch-create ,i))))
                    (number-sequence 0 9))))
  (exwm-enable) ; assuming this needs to be done before setters are enabled
  (exwm-init)
  (global-exwm-key "<XF86MonBrightnessUp>"   #'raise-brightness)
  (global-exwm-key "<XF86MonBrightnessDown>" #'lower-brightness)
  (global-exwm-key "<XF86Display>"           #'lock-screen)
  (global-exwm-key "<XF86AudioRaiseVolume>"  #'raise-volume)
  (global-exwm-key "<XF86AudioLowerVolume>"  #'lower-volume)
  (global-exwm-key "<XF86AudioMute>"         #'toggle-mute)
  (global-exwm-key "<XF86AudioPlay>"         #'spotify-toggle-play)
  (global-exwm-key "<XF86AudioPrev>"         #'spotify-prev)
  (global-exwm-key "<XF86AudioNext>"         #'spotify-next)
  (global-exwm-key "s-k"                     #'evil-window-up)
  (global-exwm-key "s-j"                     #'evil-window-down)
  (global-exwm-key "s-h"                     #'evil-window-left)
  (global-exwm-key "s-l"                     #'evil-window-right)
  (global-exwm-key "s-SPC"                   #'hydra-leader/body)
  (global-exwm-key "s-["                     #'hydra-left-leader/body)
  (global-exwm-key "s-]"                     #'hydra-right-leader/body)
  (global-exwm-key "s-x"                     #'exwm-run-command)
  (global-exwm-key "s-b"                     #'check-battery)
  (global-exwm-key "s-s"                     #'cycle-sound)
  (global-exwm-key "s-t"                     #'check-time)
  (global-exwm-key "s-L"                     #'lock-screen)
  (global-exwm-key "M-C-s-R"                 #'restart-display-manager)
  (exwm-input-set-simulation-keys
   '(([?\s-a] . ?\C-a)
     ([?\s-C] . ?\C-C)
     ([?\s-c] . ?\C-c)
     ([?\s-V] . ?\C-V)
     ([?\s-v] . ?\C-v))))
(use-package exwm-randr
  :after (exwm))

(use-package buffer-move)

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

(defun prettify-windows ()
  "Set the windows all to have 81 chars of length"
  (interactive)
  (let ((my-window (selected-window)))
    (select-window (frame-first-window))
    (while (window-next-sibling)
      (set-window-width 85)
      (evil-beginning-of-line)
      (select-window (window-next-sibling)))
    (select-window my-window)))

(defun pretty-delete-window ()
  "Cleans up after itself after deleting current window"
  (interactive)
  (recentf-save-list)
  (delete-window)
  (prettify-windows))

(provide 'core/desktop/windows)

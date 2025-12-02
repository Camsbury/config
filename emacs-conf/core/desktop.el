(require 'prelude)

(use-package exwm
  :init
  (setq exwm-workspace-show-all-buffers t)
  (setq exwm-layout-show-all-buffers t)
  :config
  (customize-set-variable 'exwm-replace nil)
  (defun global-exwm-key (key cmd)
    "bind key for use across all exwm buffers"
    (customize-set-variable 'exwm-input-global-keys
                            (add-to-list
                             'exwm-input-global-keys
                             `(,(kbd key) . ,cmd))))

  (add-hook 'exwm-update-class-hook
            (lambda ()
              (exwm-workspace-rename-buffer exwm-class-name)))
  (defun ck/exwm-force-x-focus-out (&rest _)
    "Ensure the current EXWM window receives a real FocusOut on workspace switch."
    (when (derived-mode-p 'exwm-mode)
      ;; Tell X: focus nothing (root window)
      (x-focus-frame nil)))
  (advice-add 'exwm-workspace-switch :before #'ck/exwm-force-x-focus-out)
  (defun ck/exwm-restore-focus ()
    "Restore X focus to the selected EXWM window on the current workspace."
    (let* ((win (selected-window))
           (buf (and win (window-buffer win))))
      (when (and buf
                 (with-current-buffer buf
                   (derived-mode-p 'exwm-mode))
                 (buffer-local-value 'exwm--id buf))
        (exwm-input--update-focus win))))
  (add-hook 'exwm-workspace-switch-hook
            (lambda ()
              (when (eq major-mode 'exwm-mode)
                (ck/exwm-restore-focus))))
  (customize-set-variable 'exwm-workspace-number 10)
  (customize-set-variable 'exwm-workspace-current-index 1)
  (global-exwm-key "s-," #'exwm-reset)
  (global-exwm-key "s-." #'exwm-layout-set-fullscreen)
  (dolist (i (number-sequence 0 9))
    (global-exwm-key
     (format "s-%d" i)
     `(lambda ()
        (interactive)
        (exwm-workspace-switch-create ,i))))
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
  (global-exwm-key "s-X"                     #'exwm-run-command)
  (global-exwm-key "s-b"                     #'check-battery)
  (global-exwm-key "s-s"                     #'cycle-sound)
  (global-exwm-key "s-t"                     #'check-time)
  (global-exwm-key "s-L"                     #'lock-screen)
  (global-exwm-key "<XF86Tools>"             #'restart-display-manager)
  (customize-set-variable 'exwm-input-simulation-keys
                          '(([?\s-a] . ?\C-a)
                            ([?\s-x] . ?\C-x)
                            ([?\s-C] . ?\C-C)
                            ([?\s-c] . ?\C-c)
                            ([?\s-V] . ?\C-V)
                            ([?\s-v] . ?\C-v)))
  (exwm-enable) ; assuming this needs to be done before setters are enabled
  (exwm-init))
(use-package exwm-randr
  :after (exwm))

(provide 'core/desktop)

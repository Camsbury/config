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
  (setq exwm-workspace-number 5
        exwm-workspace-current-index 1
        exwm-input-global-keys
        `(([?\s-r] . exwm-reset)
          ,@(mapcar (lambda (i)
                      `(,(kbd (format "s-%d" i)) .
                        (lambda ()
                          (interactive)
                          (exwm-workspace-switch-create ,i))))
                    (number-sequence 0 9))))
  (exwm-enable) ; assuming this needs to be done before setters are enabled
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

(provide 'core/desktop)

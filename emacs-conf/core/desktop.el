;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'exwm)
(require 'exwm-randr)

(setq exwm-workspace-show-all-buffers t)
(setq exwm-layout-show-all-buffers t)


(customize-set-variable 'exwm-replace nil)
(defun ck/global-exwm-key (key cmd)
  "bind key for use across all exwm buffers"
  (customize-set-variable 'exwm-input-global-keys
                          (add-to-list
                           'exwm-input-global-keys
                           `(,(kbd key) . ,cmd))))

(add-hook 'exwm-update-class-hook
          (lambda ()
            (exwm-workspace-rename-buffer exwm-class-name)))
(customize-set-variable 'exwm-workspace-number 10)
(customize-set-variable 'exwm-workspace-current-index 1)
(ck/global-exwm-key "s-," #'exwm-reset)
(ck/global-exwm-key "s-." #'exwm-layout-set-fullscreen)
(dolist (i (number-sequence 0 9))
  (ck/global-exwm-key
   (format "s-%d" i)
   `(lambda ()
      (interactive)
      (exwm-workspace-switch-create ,i))))
(ck/global-exwm-key "<XF86MonBrightnessUp>"   #'ck/raise-brightness)
(ck/global-exwm-key "<XF86MonBrightnessDown>" #'ck/lower-brightness)
(ck/global-exwm-key "<XF86Display>"           #'ck/lock-screen)
(ck/global-exwm-key "<XF86AudioRaiseVolume>"  #'ck/raise-volume)
(ck/global-exwm-key "<XF86AudioLowerVolume>"  #'ck/lower-volume)
(ck/global-exwm-key "<XF86AudioMute>"         #'ck/toggle-mute)
(ck/global-exwm-key "<XF86AudioPlay>"         #'ck/spotify-toggle-play)
(ck/global-exwm-key "<XF86AudioPrev>"         #'ck/spotify-prev)
(ck/global-exwm-key "<XF86AudioNext>"         #'ck/spotify-next)
(ck/global-exwm-key "s-k"                     #'evil-window-up)
(ck/global-exwm-key "s-j"                     #'evil-window-down)
(ck/global-exwm-key "s-h"                     #'evil-window-left)
(ck/global-exwm-key "s-l"                     #'evil-window-right)
(ck/global-exwm-key "s-SPC"                   #'hydra-leader/body)
(ck/global-exwm-key "s-["                     #'hydra-left-leader/body)
(ck/global-exwm-key "s-]"                     #'hydra-right-leader/body)
(ck/global-exwm-key "s-X"                     #'ck/exwm-run-command)
(ck/global-exwm-key "s-b"                     #'ck/check-battery)
(ck/global-exwm-key "s-s"                     #'ck-switch-audio-sink)
(ck/global-exwm-key "s-t"                     #'ck/check-time)
(ck/global-exwm-key "s-L"                     #'ck/lock-screen)
(ck/global-exwm-key "<XF86Tools>"             #'ck/restart-display-manager)
(customize-set-variable 'exwm-input-simulation-keys
                        '(([?\s-a] . ?\C-a)
                          ([?\s-x] . ?\C-x)
                          ([?\s-C] . ?\C-C)
                          ([?\s-c] . ?\C-c)
                          ([?\s-V] . ?\C-V)
                          ([?\s-v] . ?\C-v)))
(exwm-wm-mode)

(provide 'core/desktop)

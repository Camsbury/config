;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'exwm)
(require 'exwm-randr)

(setq exwm-workspace-show-all-buffers t)
(setq exwm-layout-show-all-buffers t)


(customize-set-variable 'exwm-replace nil)

(add-hook 'exwm-update-class-hook
          (lambda ()
            (exwm-workspace-rename-buffer exwm-class-name)))
(customize-set-variable 'exwm-workspace-number 10)
(customize-set-variable 'exwm-workspace-current-index 1)

(defun ck/set-exwm-global-keys (bindings)
  "Set EXWM global keys from a list of (KEY-STRING COMMAND) pairs.
Idempotent - replaces the full key list on each call."
  (customize-set-variable
   'exwm-input-global-keys
   (mapcar (pcase-lambda (`(,key ,cmd))
             (cons (kbd key) cmd))
           bindings)))

(defun ck/set-exwm-simulation-keys (bindings)
  "Set EXWM simulation keys from a list of (FROM-KEY TO-KEY) pairs.
Both keys are key description strings."
  (customize-set-variable
   'exwm-input-simulation-keys
   (mapcar (pcase-lambda (`(,from ,to))
             (cons (kbd from) (kbd to)))
           bindings)))

(ck/set-exwm-global-keys
 `(;; EXWM controls
   ("s-,"                    exwm-reset)
   ("s-."                    exwm-layout-set-fullscreen)
   ;; workspace switching
   ,@(--map `(,(format "s-%d" it)
              (lambda () (interactive) (exwm-workspace-switch-create ,it)))
            (number-sequence 0 9))
   ;; XF86 media/hardware keys
   ("<XF86MonBrightnessUp>"  ck/raise-brightness)
   ("<XF86MonBrightnessDown>" ck/lower-brightness)
   ("<XF86Display>"          ck/lock-screen)
   ("<XF86AudioRaiseVolume>" ck/raise-volume)
   ("<XF86AudioLowerVolume>" ck/lower-volume)
   ("<XF86AudioMute>"        ck/toggle-mute)
   ("<XF86AudioPlay>"        ck/spotify-toggle-play)
   ("<XF86AudioPrev>"        ck/spotify-prev)
   ("<XF86AudioNext>"        ck/spotify-next)
   ("<XF86Tools>"            ck/restart-display-manager)
   ;; window navigation
   ("s-k"                    evil-window-up)
   ("s-j"                    evil-window-down)
   ("s-h"                    evil-window-left)
   ("s-l"                    evil-window-right)
   ;; leaders
   ("s-SPC"                  hydra-leader/body)
   ("s-["                    hydra-left-leader/body)
   ("s-]"                    hydra-right-leader/body)
   ;; commands
   ("s-X"                    ck/exwm-run-command)
   ("s-b"                    ck/check-battery)
   ("s-s"                    ck-switch-audio-sink)
   ("s-t"                    ck/check-time)
   ("s-L"                    ck/lock-screen)))

(ck/set-exwm-simulation-keys
 '(("s-a" "C-a")
   ("s-x" "C-x")
   ("s-C" "C-C")
   ("s-c" "C-c")
   ("s-V" "C-V")
   ("s-v" "C-v")))

(exwm-wm-mode)

(provide 'core/desktop)

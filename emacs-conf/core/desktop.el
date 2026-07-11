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

;; Library command reached only through the `s-s' key below: lib/ features
;; are not in the m-require boot chain, so declare the entry stub explicitly
;; (decision 0001: autoloads never load here) and the file loads on first use.
(autoload 'ck/switch-audio-sink "lib/sound" nil t)

(ck/set-exwm-global-keys
 `(;; EXWM controls
   ("s-,"                    exwm-reset)
   ("s-."                    exwm-layout-set-fullscreen)
   ;; workspace switching
   ,@(--map `(,(format "s-%d" it)
              (lambda () (interactive) (exwm-workspace-switch-create ,it)))
            (number-sequence 0 9))
   ;; XF86 hardware keys.
   ;; Audio/media keys (volume, mute, play/prev/next) are OWNED below X by
   ;; triggerhappy (nix-conf/modules/media_keys.nix), so they keep working
   ;; while the screen is locked. But triggerhappy reads evdev BEFORE X, so
   ;; the keysym still propagates up to whichever X window has focus. We grab
   ;; these audio keys bound to `ignore' purely to SWALLOW that stray keysym:
   ;; it stops Emacs echoing "<XF86Audio...> is undefined" when an Emacs
   ;; buffer is focused, and stops a focused X app (browser, player) from
   ;; acting on the key a second time. `ignore' takes no media action, so
   ;; there is no double-fire with triggerhappy.
   ("<XF86AudioPlay>"        ignore)
   ("<XF86AudioPrev>"        ignore)
   ("<XF86AudioNext>"        ignore)
   ("<XF86AudioMute>"        ignore)
   ("<XF86AudioRaiseVolume>" ignore)
   ("<XF86AudioLowerVolume>" ignore)
   ("<XF86MonBrightnessUp>"  ck/raise-brightness)
   ("<XF86MonBrightnessDown>" ck/lower-brightness)
   ("<XF86Display>"          ck/lock-screen)
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
   ("s-e"                    ck/eca-jump-to-attention)
   ("s-i"                    ck/eca-jump-to-idle)
   ("s-b"                    ck/check-battery)
   ("s-s"                    ck/switch-audio-sink)
   ("s-t"                    ck/check-time)
   ("s-n"                    ck/dunst-toggle-mute)
   ("s-L"                    ck/lock-screen)))

(ck/set-exwm-simulation-keys
 '(("s-a" "C-a")
   ("s-x" "C-x")
   ("s-C" "C-C")
   ("s-c" "C-c")
   ("s-V" "C-V")
   ("s-v" "C-v")))

;; --- WM activation seam ---------------------------------------------------
;; Loading this file only DEFINES the WM setup; it must never enable EXWM at
;; load time, so the whole config stays usable on a plain TTY (no X).  The two
;; activation steps (become the WM, create workspaces) are gathered into
;; `ck/enable-wm', which init.el calls only when `ck/wm-session-p' is non-nil.
;; This is the TTY-vs-WM dispatch seam (decision 0016).  The WM-free load
;; invariant is machine-checked by tools/wm-free-check.sh.

(defvar ck/wm-active-p nil
  "Non-nil once `ck/enable-wm' has started EXWM in this session.
Lets any feature branch on \"am I the window manager?\" without probing
EXWM internals.  Stays nil on a TTY session.")

(defun ck/wm-session-p ()
  "Non-nil when this Emacs should act as the EXWM window manager.
True for the graphical X login session, nil on a plain TTY (where
`initial-window-system' is nil)."
  (eq initial-window-system 'x))

(defun ck/enable-wm ()
  "Become the X window manager: start EXWM and create workspaces.
Call only from a real X session (see `ck/wm-session-p'); on a TTY EXWM
cannot connect to X and would abort startup."
  (exwm-wm-mode)
  (dolist (i (number-sequence 0 9))
    (exwm-workspace-switch-create i))
  (exwm-workspace-switch 1)
  (setq ck/wm-active-p t))

(provide 'core/desktop)

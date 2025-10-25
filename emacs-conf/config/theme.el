(require 'prelude)
(require 'core/env)

(defun laptop-p ()
  (= 10
     (-> "cat /sys/class/dmi/id/chassis_type"
         shell-command-to-string
         s-trim
         string-to-number)))

(defvar normal-font-height
  (if (laptop-p)
      90
    100))


(use-package doom-modeline
  :config (doom-modeline-mode))
(use-package doom-themes
  :config
  (add-to-list 'custom-theme-load-path (concat cmacs-config-path "/config/theme/") t)
  (load-theme 'doom-molokam t)
  (set-face-attribute 'font-lock-function-name-face nil
                      :weight 'normal :inherit nil)
  (set-frame-font "Go Mono 10" nil t)
  (set-face-attribute 'default nil :height normal-font-height))
(use-package rainbow-delimiters)
(use-package rainbow-mode)

(defvar cmacs-themes
  '(doom-molokam
    doom-molokai
    doom-Iosvkem
    doom-acario-dark
    doom-dracula
    doom-material))
(defvar theme-cycle
  (nconc cmacs-themes cmacs-themes))

(defun set-theme
    (theme)
  "Set theme and resize"
  (load-theme theme t)
  (set-face-attribute 'font-lock-function-name-face nil
                      :weight 'normal :inherit nil)
  (set-face-attribute 'default nil :height normal-font-height))

(defun cycle-theme ()
  "Cycle through themes"
  (interactive)
  (let ((theme (car theme-cycle)))
    (setq theme-cycle (cdr theme-cycle))
    (set-theme theme)))

(provide 'config/theme)

(comment
 (set-theme 'doom-molokam)
 (set-theme 'doom-molokai)
 (set-theme 'doom-material-dark)
 (set-theme 'doom-Iosvkem))

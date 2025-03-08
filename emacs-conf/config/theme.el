(require 'prelude)

(use-package doom-modeline
  :config (doom-modeline-mode))
(use-package doom-themes
  :config
  (add-to-list 'custom-theme-load-path (concat cmacs-config-path "/config/theme/") t)
  (load-theme 'doom-molokam t))
(use-package rainbow-delimiters)
(use-package rainbow-mode)

(defvar themes)
(setq themes
      '(doom-molokam
        doom-molokai
        doom-Iosvkem
        doom-acario-dark
        doom-dracula
        doom-material))
(defvar theme-cycle)
(setq theme-cycle
      (nconc themes themes))


;; theme
;; FIXME: run only once
(set-frame-font "Go Mono 10" nil t)

(defvar normal-font-height)
;; FIXME: run only once


(defun laptop-p ()
  (= 10
     (-> "cat /sys/class/dmi/id/chassis_type"
         shell-command-to-string
         s-trim
         string-to-number)))

;; smaller font for laptop
(if (laptop-p)
    (setq normal-font-height 90)
  (setq normal-font-height 110))

;; FIXME: run only once
(set-face-attribute 'default nil :height normal-font-height)

(defun set-theme
    (theme)
  "Set theme and resize"
  (load-theme theme t)
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

(require 'prelude)

(use-package doom-modeline
  :config (doom-modeline-mode))
(use-package doom-themes
  :config (load-theme 'doom-molokai t))
(use-package rainbow-delimiters)
(use-package rainbow-mode)

(defvar themes)
(setq themes
      '(doom-molokai
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
;; (if (> (x-display-pixel-width) 1600)
;;     (setq normal-font-height 85)
;;   (setq normal-font-height 110))
(setq normal-font-height 110)

;; FIXME: run only once
(set-face-attribute 'default nil :height normal-font-height)

(defun set-theme
    (theme)
  "Set theme and resize"
  (load-theme theme t)
  (set-face-attribute 'default nil :height normal-font-height))

(defun cycle-theme ()
  (interactive)
  "Cycle through themes"
  (let ((theme (car theme-cycle)))
    (setq theme-cycle (cdr theme-cycle))
    (set-theme theme)))

(provide 'config/theme)

(comment
 (set-theme 'doom-material)
 (set-theme 'doom-Iosvkem))

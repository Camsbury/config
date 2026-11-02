;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'core/env)
(require 'config/theme/editor)

;; doom-modeline is deferred; its mode command is called only in the
;; `use-package :config' below (decision 0001, autoloads never load here).
(declare-functions "doom-modeline" doom-modeline-mode)

(defun ck/laptop-p ()
  (= 10
     (-> "cat /sys/class/dmi/id/chassis_type"
         shell-command-to-string
         s-trim
         string-to-number)))

(defvar normal-font-height
  (if (ck/laptop-p)
      100
    110)
  "Default face height in tenths of a point; the one source of font size.")

(defun ck/set-default-font ()
  "Set Go Mono at `normal-font-height' on all frames, current and future.
Uses the face override spec, which outranks every theme, so any theme
enable (including `consult-theme') keeps this font and size.
`set-frame-font' is the wrong tool: it rounds the height through the
font's pixel size and saves it into the user's Custom spec."
  (face-spec-set 'default
                 `((t :family "Go Mono" :height ,normal-font-height))))


(use-package doom-modeline
  :config (doom-modeline-mode))
(use-package doom-themes
  :config
  (add-to-list 'custom-theme-load-path (concat cmacs-config-path "/config/theme/") t)
  ;; The EDN is the source of truth; load it at boot.  Emacs is the window
  ;; manager, so a themeless boot is not acceptable: if the EDN fails to load
  ;; for any reason, fall back to the hand-written .el baseline.
  (condition-case err
      (ck/doom-theme-load-edn ck/doom-theme-edn-file)
    (error
     (message "doom-theme: EDN boot load failed (%s); using .el baseline"
              (error-message-string err))
     (load-theme 'doom-molokam t)))
  (set-face-attribute 'font-lock-function-name-face nil
                      :weight 'normal :inherit nil)
  (ck/set-default-font))
(use-package rainbow-delimiters)
(use-package rainbow-mode)

(defvar cmacs-themes
  '(doom-molokam
    doom-molokai
    doom-Iosvkem
    doom-acario-dark
    doom-dracula
    doom-material))
(defvar theme-cycle cmacs-themes
  "Remaining themes to cycle through; refilled from `cmacs-themes' when empty.")

(defun ck/set-theme
    (theme)
  "Set THEME.
If an EDN source exists for THEME in `ck/doom-theme-dir', load it through
the EDN pipeline so cycling to it matches the authoritative boot render;
otherwise fall back to `load-theme'."
  (let ((edn (expand-file-name (format "%s.edn" theme) ck/doom-theme-dir)))
    (if (file-exists-p edn)
        (ck/doom-theme-load-edn edn)
      (load-theme theme t)))
  (set-face-attribute 'font-lock-function-name-face nil
                      :weight 'normal :inherit nil))

(defun ck/cycle-theme ()
  "Cycle through themes"
  (interactive)
  (unless theme-cycle
    (setq theme-cycle cmacs-themes))
  (let ((theme (car theme-cycle)))
    (setq theme-cycle (cdr theme-cycle))
    (ck/set-theme theme)))

(provide 'config/theme)

(comment
 (ck/set-theme 'doom-molokam)
 (ck/set-theme 'doom-molokai)
 (ck/set-theme 'doom-material-dark)
 (ck/set-theme 'doom-Iosvkem))

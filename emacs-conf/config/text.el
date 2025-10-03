(require 'prelude)
(require 'core/env)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Evil

(use-package evil-commentary
  :after (evil)
  :config (evil-commentary-mode))
(use-package evil-multiedit
  :after (evil))
(use-package evil-surround
  :after (evil)
  :config (evil-surround-mode))
(use-package evil-visualstar
  :after (evil)
  :config (evil-visualstar-mode))

(defun evil-save-as (arg)
  "Save buffer as"
  (interactive "sFile name: ")
  (evil-save arg))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Useful Packages

(use-package avy)
(use-package nav-flash
  :config
  (defun nav-flash-line ()
    (interactive)
    (nav-flash-show)))
(use-package define-word)
(use-package etymology-of-word)
(use-package string-edit-at-point)
(use-package undo-tree
  :config
  (setq undo-tree-history-directory-alist '(("." . "~/.cache/emacs/undo-tree/")))
  (customize-set-variable 'evil-undo-system 'undo-tree)
  (global-undo-tree-mode))
(use-package yasnippet
  :config
  (setq yas-snippet-dirs
        (append yas-snippet-dirs `(,(concat cmacs-config-path "/snippets/")))
        yas-snippet-dirs
        (append yas-snippet-dirs `(,(concat cmacs-share-path "/snippets/"))))
  (yas-global-mode 1)
  (setq yas-triggers-in-field t))
(use-package company
  :config
  (setq company-minimum-prefix-length 2
        company-tooltip-limit 14
        company-tooltip-align-annotations t
        company-require-match 'never
        company-idle-delay 0.7
        company-global-modes
        '(not erc-mode
              circe-mode
              message-mode
              help-mode
              gud-mode
              vterm-mode)
        ;; lsp-completion-provider :capf
        )
  ;; (global-company-mode)
  )
(use-package company-box
  :hook (company-mode . company-box-mode))

(use-package corfu
  :config
  (global-corfu-mode)
  (setq corfu-auto t))

(use-package kind-icon
  :after corfu
  :custom
  (kind-icon-default-face 'corfu-default)
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file))

(defun ck/point-to-right-columns ()
  "Visible columns from point to the right window edge."
  (let* ((win (selected-window))
         (col (current-column))         ; 0-based buffer column
         (h   (window-hscroll win))     ; leftmost visible buffer column
         (w   (window-body-width win))  ; visible width in columns
         (right (+ h w -1)))
    (max 0 (- (- right col) 5))))

(defun ck/beacon-update-size (&rest _)
  (setq beacon-size (ck/point-to-right-columns)))

(use-package beacon
  :init
  (setq beacon-blink-when-point-moves-horizontally 0
        beacon-blink-when-point-moves-vertically   1
        beacon-blink-when-focused t
        beacon-blink-duration 0.05
        beacon-blink-delay 0.1
        beacon-dont-blink-commands nil
        beacon-push-mark nil
        beacon-color "#00FF58")
  :config
  (add-to-list 'beacon-dont-blink-major-modes 'exwm-mode)
  (advice-add 'beacon-blink :before #'ck/beacon-update-size)
  ;; (beacon-mode 1)
  )

;; (use-package corfu)
;; (use-package kind-icon
;;   :ensure t
;;   :after corfu
;;   :config
;;   (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Utility Functions

(defun increment-number-at-point ()
  (interactive)
  (skip-chars-backward "0-9")
  (or (looking-at "[0-9]+")
      (error "No number at point"))
  (replace-match (number-to-string (1+ (string-to-number (match-string 0))))))

(defun copy-buffer-path ()
  "Copies the path of the current buffer"
  (interactive)
  (kill-new (buffer-file-name)))

(defun narrow-and-zoom-in ()
  "Narrow to selection and zoom in"
  (interactive)
  (call-interactively 'narrow-to-region)
  (call-interactively 'text-scale-increase)
  (call-interactively 'text-scale-increase)
  (call-interactively 'text-scale-increase)
  (set-window-width (selected-window) 130))

(defun widen-and-zoom-out ()
  "Widen the buffer and set zoom to normal"
  (interactive)
  (save-mark-and-excursion (call-interactively 'widen)
   (call-interactively 'text-scale-set)
   (call-interactively 'text-scale-decrease)
   (prettify-windows)))


(provide 'config/text)

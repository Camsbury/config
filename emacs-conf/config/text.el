(require 'prelude)

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
(use-package string-edit)
(use-package undo-tree
  :config
  (customize-set-variable 'evil-undo-system 'undo-tree)
  (global-undo-tree-mode))
(use-package yasnippet
  :config
  (setq yas-snippet-dirs
        (append yas-snippet-dirs `(,(concat (getenv "CONFIG_PATH") "/snippets/")))
        yas-snippet-dirs
        (append yas-snippet-dirs `(,(concat (getenv "HOME") "/Dropbox/lxndr/snippets/"))))
  (yas-global-mode 1)
  (setq yas-triggers-in-field t))
(use-package company
  :config
  (setq lsp-completion-provider :capf)
  (global-company-mode))


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

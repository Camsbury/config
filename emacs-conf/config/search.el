(require 'prelude)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Counsel

(use-package counsel
  :init (setq counsel-find-file-ignore-regexp "[~\#]$")
  :config
  (setq counsel-rg-base-command
        "rg -S --ignore-file $HOME/.rgignore --no-heading --line-number \
--hidden --color never %s ."
        counsel-describe-function-function #'helpful-callable
        counsel-describe-variable-function #'helpful-variable))

(use-package projectile
  :config (projectile-mode))
(use-package counsel-projectile
  :after (counsel projectile))

(customize-set-variable 'projectile-project-search-path '(("~/projects" . 2)))

(setq projectile-ignores
      (rx (or
           ".metals"
           (seq bos (any "#."))
           (seq
            (or
             (any "#~")
             ".class"
             ".png"
             ".svg")
            eos))))
(setq find-file-ignores
      (rx (or
           (seq bos (any "#."))
           (seq (any "#~") eos))))

(defun ignorify (file-ignore-regexp f)
  "add local ignores to function"
  (let ((counsel-find-file-ignore-regexp file-ignore-regexp))
    (call-interactively f)))

;; (setq projectile-globally-ignored-file-suffixes '("~" "#"))
;; (customize-set-variable 'projectile-globally-ignored-directories
;;                         (add-to-list 'projectile-globally-ignored-directories ".github"))
;; required to use counsel-projectile
(setq projectile-keymap-prefix (kbd "C-c C-p"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Ivy

(use-package ivy
  :init (setq ivy-initial-inputs-alist nil
              ivy-format-function 'ivy-format-function-line)
  :config (ivy-mode)
  (general-emacs-define-key ivy-minibuffer-map
    [escape] 'minibuffer-keyboard-quit)
  (custom-set-faces
   '(ivy-current-match ((t (:background "#3a403a"))))))
(use-package ivy-hydra
  :after (ivy hydra))
(use-package ivy-xref
  :after (ivy))
(use-package ivy-rich
  :after (ivy)
  :init (setq ivy-rich-path-style 'abbrev)
  :config (ivy-rich-mode 1))
(use-package all-the-icons-ivy-rich
  :after (ivy-rich)
  :config (all-the-icons-ivy-rich-mode 1))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Others

(use-package smex)
(use-package wgrep
  :config
  (defun wgrep-save-and-quit ()
    "wgrep save everything and quet the window"
    (interactive)
    (wgrep-finish-edit)
    (wgrep-save-all-buffers)
    (quit-window))
  (general-define-key
   :keymaps 'wgrep-mode-map
   [remap evil-save-modified-and-close] #'wgrep-save-and-quit))
(use-package dumb-jump
  :init
  (setq dumb-jump-selector        'ivy
        dumb-jump-prefer-searcher 'rg))
(general-emacs-define-key xref--button-map
  "q"   #'quit-window
  "RET" #'xref-goto-xref)

(recentf-mode)
(minibuffer-electric-default-mode)

(provide 'config/search)

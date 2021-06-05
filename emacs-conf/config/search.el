;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Counsel

(use-package counsel
  :init (setq counsel-find-file-ignore-regexp "[~\#]$")
  :config
  (setq counsel-rg-base-command
        "rg -S -g !'*.lock' -g !'.git' -g !'node_modules' -g !'yarn' \
--no-heading --line-number --hidden --color never %s ."
        counsel-describe-function-function #'helpful-callable
        counsel-describe-variable-function #'helpful-variable))

(use-package projectile
  :config (projectile-mode))
(use-package counsel-projectile
  :after (counsel projectile))

(projectile-discover-projects-in-directory "~/projects")
(setq projectile-globally-ignored-file-suffixes '("~" "#"))
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


(recentf-mode)
(minibuffer-electric-default-mode)

(provide 'config/search)

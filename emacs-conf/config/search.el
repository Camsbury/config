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

(customize-set-variable
 'projectile-project-search-path '(("~/projects" . 2)))

(customize-set-variable
 'projectile-ignored-project-function
 (lambda (project)
   (string-match
    (rx
     (or
      (seq bos "/nix")
      (seq "/."
           (one-or-more (not (any "/.")))
           eos)
      ".git"
      "dist"
      "dist-newstyle"))
    project)))

(defvar projectile-ignores nil
  "stuff to ignore in a project setting")
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

(defvar find-file-ignores nil
  "stuff to ignore when calling find-file derivatives")
(setq find-file-ignores
      (rx (or
           (seq bos (any "#."))
           (seq (any "#~") eos))))

(defun ignorify (file-ignore-regexp f)
  "add local ignores to function"
  (let ((counsel-find-file-ignore-regexp file-ignore-regexp))
    (call-interactively f)))

(customize-set-variable
 'projectile-keymap-prefix (kbd "C-c C-p"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Ivy

(use-package ivy
  :init (setq ivy-initial-inputs-alist nil
              ivy-format-function 'ivy-format-function-line)
  :config (ivy-mode)
  (general-emacs-define-key ivy-minibuffer-map
    [escape] 'minibuffer-keyboard-quit)
  (general-emacs-define-key ivy-occur-mode-map
    [evil-ret] #'ivy-occur-click)
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

(general-def :keymaps 'ivy-occur-grep-mode-map
  "D" #'ivy-occur-delete-candidate)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Others

(use-package smex)

(use-package wgrep
  :config
  (defun wgrep-save-and-quit ()
    "wgrep save everything and quit the window"
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
  "q"   #'kill-buffer-and-window
  "RET" #'xref-goto-xref)

(customize-set-variable
 'recentf-max-saved-items 100)
(customize-set-variable
 'recentf-exclude
 (list
  (rx
   (or ".metals"
       ".m2"
       ".emacs.d/emms"
       ".elfeed"
       (seq bos "/nix")))))
(recentf-mode)
(minibuffer-electric-default-mode)

(provide 'config/search)

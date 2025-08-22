(require 'prelude)
(require 'core/env)
(require 'core/bindings)


(use-package projectile
  :config (projectile-mode)

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

  (customize-set-variable
   'projectile-keymap-prefix (kbd "C-c C-p"))

  (customize-set-variable
   'projectile-current-project-on-switch 'keep))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Ivy - keeping around for things that depend on it, but don't use it globally

(use-package ivy
  :demand nil)
(use-package ivy-rich
  :after (ivy)
  :config (setq ivy-rich-mode nil))
(use-package all-the-icons-ivy-rich
  :after (ivy-rich))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Others

(use-package smex)

(use-package wgrep
  :config
  (setq wgrep-change-readonly-file t)
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
  (setq dumb-jump-prefer-searcher 'rg))

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
(savehist-mode 1)
(setq history-length 500
      history-delete-duplicates nil)
(minibuffer-electric-default-mode)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Emacs Nouveau

;; core UI
(use-package vertico
  :config
  (vertico-mode 1)
  (require 'vertico-sort)
  (setq
   vertico-resize nil
   vertico-count 17
   vertico-cycle t
   vertico-sort-function #'vertico-sort-history-length-alpha)
  (setq-default
   completion-in-region-function
   (lambda (&rest args)
     (apply (if vertico-mode
                #'consult-completion-in-region
              #'completion--in-region)
            args)))
  (general-define-key
   :keymaps 'vertico-map
   "M-RET" #'vertico-exit-input
   "C-j"   #'vertico-next
   "C-M-j" #'vertico-next-group
   "C-k"   #'vertico-previous
   "C-M-k" #'vertico-previous-group
   [escape] #'minibuffer-keyboard-quit))

;; NOTE: still want this to only work for find-file
;; Configure directory extension.
(use-package vertico-directory
  :after vertico
  :ensure nil
  ;; More convenient directory navigation commands
  :bind (:map vertico-map
              ("M-DEL" . #'vertico-directory-up)
              ("RET" . vertico-directory-enter))
  ;; Tidy shadowed file names
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles . (partial-completion)))))
  ;; Space-separated components; escape space with \  when needed.
  (orderless-component-separator #'orderless-escapable-split-on-space))
;; Enable rich annotations using the Marginalia package
(use-package marginalia
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :demand t
  :bind (:map minibuffer-local-map
              ("M-a" . marginalia-cycle))

  :config
  (marginalia-mode 1)
  (general-define-key :keymaps 'minibuffer-local-map
   "M-a" #'marginalia-cycle))
(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))
;; power commands / actions
(use-package consult
  :preface
  (general-define-key
   :keymaps 'global-map
   [remap bookmark-jump]                 #'consult-bookmark
   [remap evil-show-marks]               #'consult-mark
   [remap evil-show-registers]           #'consult-register
   [remap goto-line]                     #'consult-goto-line
   [remap imenu]                         #'consult-imenu
   [remap Info-search]                   #'consult-info
   [remap locate]                        #'consult-locate
   [remap load-theme]                    #'consult-theme
   [remap recentf-open-files]            #'consult-recent-file
   [remap switch-to-buffer]              #'consult-buffer
   [remap switch-to-buffer-other-window] #'consult-buffer-other-window
   [remap switch-to-buffer-other-frame]  #'consult-buffer-other-frame
   [remap yank-pop]                      #'consult-yank-pop)
  :config
  (setq consult-ripgrep-args
        (concat
         "rg --null --line-buffered --color=never --max-columns=1000 \
          --path-separator / --smart-case --no-heading --line-number \
          --hidden --ignore-file "
         user-home-path
         "/.rgignore")
        consult-narrow-key "<"
        consult-line-numbers-widen t
        consult-async-min-input 2
        consult-async-refresh-delay  0.15
        consult-async-input-throttle 0.2
        consult-async-input-debounce 0.1))
(use-package consult-imenu)
(use-package consult-projectile)
(use-package embark
  ;; NOTE: you want to C-c C-p after this to edit all
  :bind (("C-c C-o" . embark-export)
         ("C-." . embark-act)))
(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(with-eval-after-load 'grep
  (evil-set-initial-state 'grep-mode 'normal)
  (general-evil-define-key 'normal 'grep-mode-map
    "q" #'quit-window))

(provide 'config/search)

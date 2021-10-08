(require 'prelude)

(use-package lsp-mode
  :config
  (-map (-applify #'customize-set-variable)
        '((lsp-server-trace "verbose") ;; gimme logs!
          (lsp-log-io       t)         ;; log more!
          (lsp-lens-enable  t))) ;; do cool stuff!

  ;; hack to get rid of the annoying command map, which seems broken currently
  (let ((lsp-mode-map
         (let ((map (make-sparse-keymap)))
           (define-key map (kbd "C-<down-mouse-1>") #'lsp-find-definition-mouse)
           (define-key map (kbd "C-<mouse-1>") #'ignore)
           (define-key map (kbd "<mouse-3>") #'lsp-mouse-click)
           (define-key map (kbd "C-S-SPC") #'lsp-signature-activate)
           (define-key map (kbd "s-o") lsp-command-map)
           map)))
    (define-minor-mode lsp-mode ""
      :keymap lsp-mode-map
      :lighter
      (" LSP["
       (lsp--buffer-workspaces
        (:eval (mapconcat #'lsp--workspace-print lsp--buffer-workspaces "]["))
        (:propertize "Disconnected" face warning))
       "]")
      :group 'lsp-mode)))



;; lsp perf
(setq gc-cons-threshold       100000000      ;; 100mb
      read-process-output-max (* 1024 1024)) ;; 1mb



(use-package lsp-ui)
(require 'lsp-ui-flycheck)
(require 'lsp-modeline)
(require 'lsp-headerline)
(require 'lsp-modeline)
(require 'lsp-completion)
(require 'lsp-diagnostics)
(use-package posframe)
(use-package dap-mode)
(use-package dap-mouse)
(use-package dap-ui)
(use-package lsp-treemacs
  :after
  (lsp-mode treemacs)
  :config
  (lsp-treemacs-sync-mode 1))

(general-def 'normal lsp-mode-map
  [remap evil-goto-definition] #'lsp-find-definition)

(general-def
 :states  'normal
 :keymaps 'lsp-ui-imenu-mode-map
 "q" 'lsp-ui-imenu--kill)

(provide 'config/services/lsp)

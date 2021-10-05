(require 'prelude)

(use-package lsp-mode
  :hook  (scala-mode . lsp)
  (lsp-mode . lsp-lens-mode)
  :config
  (setq gc-cons-threshold 100000000) ;; 100mb
  (setq read-process-output-max (* 1024 1024)) ;; 1mb
  (setq lsp-idle-delay 0.500)
  (setq lsp-log-io nil)
  (setq lsp-completion-provider :capf)
  (setq lsp-prefer-flymake nil))

(use-package lsp-ui
  :after (lsp-mode))
(use-package lsp-ui-flycheck
  :after (lsp-ui))

(use-package posframe)
(use-package dap-mode
  :after (lsp-mode)
  :hook
  (lsp-mode . dap-mode))
(use-package dap-ui
  :after (dap-mode)
  :hook
  (lsp-mode . dap-ui-mode))

(with-eval-after-load 'lsp-mode
  (general-add-hook 'lsp-after-open-hook
                    (lambda () (lsp-ui-flycheck-enable 1))))

(general-def 'normal lsp-mode-map
  "s-l" #'evil-window-right
  [remap evil-goto-definition] #'lsp-find-definition)

(general-def
 :states  'normal
 :keymaps 'lsp-ui-imenu-mode-map
 "q" 'lsp-ui-imenu--kill)

(provide 'config/services/lsp)

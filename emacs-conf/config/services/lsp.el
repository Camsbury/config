;; -*- lexical-binding: t; -*-
(require 'prelude)

(use-package lsp-mode
  :custom
  (lsp-keymap-prefix "s-o")
  (lsp-server-trace "verbose") ;; gimme logs!
  (lsp-log-io       t)         ;; log more!
  (lsp-lens-enable  t) ;; do cool stuff!
  (lsp-idle-delay 0.6)
  (lsp-keep-workspace-alive nil))

;; lsp perf. NB: no gc-cons-threshold here on purpose. It used to setq 100MB
;; globally, which fought (and lowered) the steady-state GC configured in
;; init.el / config/performance.el. GC is now owned solely by ck/gc-idle-install
;; (256MB + idle collection); this file only bumps the process-output buffer so
;; a chatty language server's stdout is read in bigger chunks.
(setq read-process-output-max (* 1024 1024)) ;; 1mb

(use-package lsp-ui)
(require 'lsp-ui-flycheck)
(require 'lsp-modeline)
(require 'lsp-headerline)
(require 'lsp-modeline)
(require 'lsp-completion)
(require 'lsp-diagnostics)
(use-package dap-mode)
(use-package dap-ui
  :after (dap-mode)
  :config
  (dap-ui-mode)
  (dap-ui-controls-mode 1)

  (require 'dap-lldb)
  (require 'dap-gdb-lldb)
  ;; installs .extension/vscode
  (dap-gdb-lldb-setup)
  (dap-register-debug-template
   "Rust::LLDB Run Configuration"
   (list :type "lldb"
         :request "launch"
         :name "LLDB::Run"
	 :gdbpath "rust-lldb"
         :target nil
         :cwd nil)))
(use-package dap-mouse)
(add-hook 'dap-stopped-hook
          (lambda (arg) (call-interactively #'dap-hydra)))

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

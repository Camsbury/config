(setq haskell-process-use-presentation-mode t)
(setq haskell-interactive-mode-scroll-to-bottom t)
(setq haskell-process-type 'cabal-repl)

(require 'lsp-haskell)

(general-add-hook 'haskell-mode-hook
                  (list 'lsp-mode
                        #'lsp-haskell-enable
                        'flycheck-mode
                        'rainbow-delimiters-mode))

(my-mode-leader-def
 :states  'normal
 :keymaps 'haskell-mode-map
 "l" 'haskell-process-load-file
 "i" 'haskell-process-do-info
 )

(provide 'haskell-conf)

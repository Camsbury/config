(setq haskell-process-use-presentation-mode t)
(setq haskell-interactive-mode-scroll-to-bottom t)
(setq haskell-process-type 'cabal-repl)

(general-add-hook 'haskell-mode-hook
                  (list 'eldoc-mode
                        'rainbow-delimiters-mode))

(my-mode-leader-def
 :states  'normal
 :keymaps 'haskell-mode-map
 "l" 'haskell-process-load-file
 "i" 'haskell-process-do-info
 )

(provide 'haskell-conf)

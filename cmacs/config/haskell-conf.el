(setq haskell-process-use-presentation-mode t)
(setq haskell-interactive-mode-scroll-to-bottom t)
(setq haskell-process-type 'cabal-repl)

(require 'lsp-haskell)

(defun setup-lsp-if-hie ()
  "only starts lsp-mode for haskell if hie available"
  (let ((hie-directory (locate-dominating-file default-directory "hie.sh")))
    (when hie-directory
      (setq-local lsp-haskell-process-path-hie (expand-file-name "hie.sh" hie-directory))
      (lsp-mode)
      (lsp-haskell-enable))))

(general-add-hook 'haskell-mode-hook
                  (list 'setup-lsp-if-hie
                        'flycheck-mode
                        'rainbow-delimiters-mode))

(my-mode-leader-def
 :states  'normal
 :keymaps 'haskell-mode-map
 "l" 'haskell-process-load-file
 "i" 'haskell-process-do-info
 )

(provide 'haskell-conf)

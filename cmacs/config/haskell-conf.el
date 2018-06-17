(setq haskell-process-use-presentation-mode t)
(setq haskell-interactive-mode-scroll-to-bottom t)
(setq haskell-process-type 'cabal-repl)

(require 'lsp-haskell)
(require 'lsp-conf)

(defun setup-lsp-if-hie ()
  "only starts lsp-mode for haskell if hie available"
  (let ((hie-directory (locate-dominating-file default-directory "hie.sh")))
    (when hie-directory
      (setq-local lsp-haskell-process-path-hie (expand-file-name "hie.sh" hie-directory))
      (lsp-mode)
      (lsp-haskell-enable))))

(defun dante-init ()
  "runs a cabal new-repl in the nix-shell"
  (setq-default
       dante-repl-command-line-methods-alist
       `(
         (nix-new .
                  ,(lambda (root)
                     (dante-repl-by-file
                      (projectile-project-root)
                      '("shell.nix")
                      `("nix-shell" "--run" "cabal repl"
                        ,(concat (projectile-project-root) "/shell.nix")))))
         (bare  . ,(lambda (_) '("cabal" "repl"))))))


(general-add-hook 'dante-mode-hook
   '(lambda () (flycheck-add-next-checker 'haskell-dante
                '(warning . haskell-hlint))))

(general-add-hook 'haskell-mode-hook
                  (list 'setup-lsp-if-hie
                        'dante-init
                        'dante-mode
                        'hlint-refactor-mode
                        'flycheck-mode
                        'rainbow-delimiters-mode))

(my-mode-leader-def
 :states  'normal
 :keymaps 'haskell-mode-map
 "l" 'haskell-process-load-file
 "i" 'dante-info
 "r" 'dante-restart
 "t" 'hlint-refactor-at-point
 "T" 'hlint-refactor-refactor-buffer)

(provide 'haskell-conf)

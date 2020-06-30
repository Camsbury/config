(require 'bindings-conf)
(require 'lsp-haskell)
(require 'services/lsp-conf)
(require 'haskell-font-lock)

(setq haskell-process-use-presentation-mode t)
(setq haskell-interactive-mode-scroll-to-bottom t)
(setq haskell-process-type 'cabal-repl)
(setq haskell-font-lock-symbols-alist (-reject
                                       (lambda (elem)
                                         (string-equal "()" (car elem)))
                                       haskell-font-lock-symbols-alist))
(setq haskell-font-lock-symbols-alist (cons '("^." "⌾" haskell-font-lock-dot-is-not-composition) haskell-font-lock-symbols-alist))
(setq haskell-font-lock-symbols-alist (cons '("<>" "⊕" haskell-font-lock-dot-is-not-composition) haskell-font-lock-symbols-alist))
(setq haskell-font-lock-symbols-alist (cons '("->" "⟶" haskell-font-lock-dot-is-not-composition) haskell-font-lock-symbols-alist))
(setq haskell-font-lock-symbols-alist (cons '("<-" "⟵" haskell-font-lock-dot-is-not-composition) haskell-font-lock-symbols-alist))
(setq haskell-font-lock-symbols t)


(setq flymake-no-changes-timeout nil)
(setq flymake-start-syntax-check-on-newline nil)
(setq flycheck-check-syntax-automatically '(save mode-enabled))

(defun setup-lsp-if-hie ()
  "only starts lsp-mode for haskell if hie available"
  (let ((hie-directory (locate-dominating-file default-directory "hie.sh")))
    (when hie-directory
      (setq-local lsp-haskell-process-path-hie (expand-file-name "hie.sh" hie-directory))
      (lsp-haskell-enable))))


(setq dante-methods-alist
      `((new-build "cabal.project.local" ("cabal" "new-repl" (or dante-target (dante-package-name) nil) "--builddir=dist/dante"))
        (bare-cabal ,(lambda (d) (directory-files d t "..cabal$")) ("cabal" "new-repl" (or dante-target (dante-package-name) nil) "--builddir=dist/dante"))
        (bare-ghci ,(lambda (_) t) ("ghci"))))

;; (setq-default
;;      dante-repl-command-line-methods-alist
;;      `(
;;        (nix-new .
;;                 ,(lambda (root)
;;                    (dante-repl-by-file
;;                     (projectile-project-root)
;;                     '("shell.nix")
;;                     `("nix-shell" "--run" "cabal new-repl"))))
;;        (bare  . ,(lambda (_) '("cabal" "new-repl")))))


(general-add-hook 'dante-mode-hook
   '(lambda () (flycheck-add-next-checker 'haskell-dante
                '(warning . haskell-hlint))))


(general-add-hook 'haskell-mode-hook
                  (list
                   ;; 'setup-lsp-if-hie
                        'hlint-refactor-mode
                        'flycheck-mode
                        'dante-mode))

(general-def 'normal haskell-mode-map
 [remap empty-mode-leader] #'hydra-haskell/body
 )

(defhydra hydra-haskell (:exit t)
  "haskell-mode"
 ("e" #'haskell-align-imports            "align imports")
 ("s" #'haskell-sort-imports             "sort imports")
 ("i" #'dante-info                       "dante info")
 ("l" #'haskell-process-load-file        "load file")
 ("r" #'dante-restart                    "dante restart")
 ("t" #'hlint-refactor-refactor-at-point "hlint point")
 ("T" #'hlint-refactor-refactor-buffer   "hlint buffer")
 ("y" #'dante-type-at                    "dante type"))

(provide 'langs/haskell-conf)

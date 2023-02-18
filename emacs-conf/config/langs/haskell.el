(use-package haskell)
(use-package haskell-mode
  :config
  (setq haskell-compile-cabal-build-command
        "cabal new-build --ghc-option=-ferror-spans"))
(use-package haskell-font-lock
  :after (haskell-mode)
  :config
  (setq haskell-font-lock-symbols-alist
        '(("!!" . "‼")
          ("&&" . "∧")
          ("-<" . "↢")
          ("->" . "→")
          ("->" . "⟶")
          ("." "∘" haskell-font-lock-dot-is-not-composition)
          (".=" . "≗")
          (".~" . "≃")
          ("/=" . "≢")
          ("::" . "∷")
          ("<-" . "←")
          ("<-" . "⟵")
          ("<=" . "≤")
          ("<=<" . "↢")
          ("<>" . "⊕")
          ("=<<" . "⇤")
          ("==" . "≡")
          ("=>" . "⇒")
          (">=" . "≥")
          (">=>" . "↣")
          (">>=" . "⇥")
          ("\\" . "λ")
          ("^." . "⌾")
          ("^.." . "⁞")
          ("^?" . "⍉")
          ("forall" . "∀")
          ("not" . "¬")
          ("pi" . "π")
          ("sqrt" . "√")
          ("undefined" . "⊥")
          ("||" . "∨")
          ("~>" . "⇝"))
        haskell-font-lock-symbols t
        haskell-process-use-presentation-mode t
        haskell-interactive-mode-scroll-to-bottom t
        haskell-process-type 'cabal-repl))

(use-package lsp-haskell
  :after lsp-mode
  :custom
  (lsp-haskell-server-path "haskell-language-server")
  :config
  (add-hook 'haskell-mode-hook #'lsp-deferred))

(use-package hlint-refactor
  :after (haskell-mode)
  :hook  (haskell-mode . hlint-refactor-mode))

(use-package flycheck-haskell
  :after (haskell-mode)
  :hook  (haskell-mode . flycheck-mode)
  :init
  (setq flymake-no-changes-timeout nil
        flymake-start-syntax-check-on-newline nil
        flycheck-check-syntax-automatically '(save mode-enabled)))


(use-package company-cabal
  :after (company))

(defun haskell-clean-and-compile ()
  (interactive)
  (let ((haskell-compile-cabal-build-command
         "cabal clean && cabal new-build --ghc-option=-ferror-spans"))
    (haskell-compile)))

(defun haskell-run ()
  (interactive)
  (let ((haskell-compile-cabal-build-command
         "cabal run"))
    (haskell-compile)))

(general-def 'normal haskell-mode-map
  [remap empty-mode-leader] #'hydra-haskell/body)

(defhydra hydra-haskell (:exit t)
  "haskell-mode"
  ("a" #'lsp-execute-code-action          "execute code action")
  ("c" #'haskell-compile                  "compile!")
  ("C" #'haskell-clean-and-compile        "clean and compile!")
  ("R" #'haskell-run                      "run!")
  ("d" #'lsp-doc-show                     "show docs")
  ("e" #'haskell-align-imports            "align imports")
  ("s" #'haskell-sort-imports             "sort imports")
  ("l" #'lsp-lens-mode                    "toggle lenses")
  ("r" #'lsp-restart-workspace            "restart lsp workspace")
  ("t" #'hlint-refactor-refactor-at-point "hlint point")
  ("T" #'hlint-refactor-refactor-buffer   "hlint buffer")
  )

(provide 'config/langs/haskell)

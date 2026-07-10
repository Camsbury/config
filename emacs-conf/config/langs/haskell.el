;; -*- lexical-binding: t; -*-
(require 'prelude)
;; defhydra/general-def macros come from here, so they expand in byte-compile
;; isolation instead of depending on the core/bindings hub.
(require 'core/definers)
;; haskell-mode owns this; declare so the :config setq doesn't warn.
(declare-vars haskell-interactive-mode-scroll-to-bottom)

(use-package haskell)
(use-package haskell-mode
  :config
  (setq haskell-compile-cabal-build-command
        "cabal new-build --ghc-option=-ferror-spans"
        haskell-process-use-presentation-mode t
        haskell-interactive-mode-scroll-to-bottom t
        haskell-process-type 'cabal-repl))
(use-package haskell-font-lock
  :after (haskell-mode)
  :config
  (setq haskell-font-lock-symbols-alist
        '(("!!" . "‼")
          ("&&" . "∧")
          ("-<" . "↢")
          ("->" . "→")
          ("." "∘" haskell-font-lock-dot-is-not-composition)
          (".=" . "≗")
          (".~" . "≃")
          ("/=" . "≢")
          ("::" . "∷")
          ("<-" . "←")
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
        haskell-font-lock-symbols t))

(use-package lsp-haskell
  :after lsp-mode
  :custom
  (lsp-haskell-server-path "haskell-language-server")
  :config
  (add-hook 'haskell-mode-hook #'lsp-deferred))

(use-package hlint-refactor
  :after (haskell-mode)
  :hook  (haskell-mode . hlint-refactor-mode))

;; TODO: autoloads need looking into: `:after' + `:hook' emit no `require',
;; so this never loads; and even loaded it would do nothing, since the hook
;; here just re-adds flycheck-mode instead of flycheck-haskell-setup.
(use-package flycheck-haskell
  :after (haskell-mode)
  :hook  (haskell-mode . flycheck-mode)
  :init
  ;; `flymake-start-syntax-check-on-newline' is obsolete (27.1) and inert, so
  ;; it is dropped here rather than set.
  (setq flymake-no-changes-timeout nil
        flycheck-check-syntax-automatically '(save mode-enabled)))

(use-package company-cabal
  :after (company))

(defun ck/haskell-clean-and-compile ()
  (interactive)
  (let ((haskell-compile-cabal-build-command
         "cabal clean && cabal new-build --ghc-option=-ferror-spans"))
    (haskell-compile)))

(defun ck/haskell-run ()
  (interactive)
  (let ((haskell-compile-cabal-build-command
         "cabal run"))
    (haskell-compile)))

(defun ck/haskell-ghcid ()
  (interactive)
  (let ((haskell-compile-cabal-build-command
         "ghcid --command=\"cabal new-repl\""))
    (haskell-compile)))

(general-def 'normal haskell-mode-map
  [remap ck/empty-mode-leader] #'hydra-haskell/body)

(defun ck/haskell-toggle-type-nav ()
  (interactive)
  (let* ((path (buffer-file-name))
         (type-file-p
          (string-match
           (rx (seq bos (one-or-more any) "/Type.hs" eos))
           path))
         (base
          (if type-file-p
              (progn
                (string-match
                 (rx (seq bos (group (one-or-more any)) "/Type.hs" eos))
                 path)
                (match-string 1 path))
            (progn
              (string-match
               (rx (seq bos (group (one-or-more any)) ".hs" eos))
               path)
              (match-string 1 path))))
         (suffix
          (if type-file-p ".hs" "/Type.hs"))
         (alt-file (concat base suffix)))
    (if (file-exists-p alt-file)
      (find-file alt-file)
      (message "No corresponding type module"))))

(defhydra hydra-haskell (:exit t)
  "haskell-mode"
  ("C" #'ck/haskell-clean-and-compile      "clean and compile!")
  ("L" #'flycheck-list-errors           "list errors")
  ("R" #'lsp-workspace-restart          "restart lsp workspace")
  ("T" #'hlint-refactor-refactor-buffer "hlint buffer")
  ("a" #'lsp-execute-code-action        "execute code action")
  ("c" #'haskell-compile                "compile!")
  ("d" #'lsp-doc-show                   "show docs")
  ("e" #'haskell-align-imports          "align imports")
  ("g" #'ck/haskell-ghcid                  "ghcid imports")
  ("i" #'lsp-describe-thing-at-point    "describe at point")
  ("l" #'lsp-lens-mode                  "toggle lenses")
  ("r" #'ck/haskell-run                    "run!")
  ("s" #'haskell-sort-imports           "sort imports")
  ("t" #'ck/haskell-toggle-type-nav        "hlint point"))

(provide 'config/langs/haskell)

;; use-package config + hydra: forward-refs deferred lsp/haskell commands and
;; hydra-haskell/body, invoked only at runtime.  Suppress the unresolved class.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:

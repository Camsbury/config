(use-package haskell)
(use-package haskell-mode)
(use-package haskell-font-lock
  :after (haskell-mode)
  :config
  (setq haskell-font-lock-symbols-alist
        (-reject
         (lambda (elem) (string-equal "()" (car elem)))
         haskell-font-lock-symbols-alist)

        haskell-font-lock-symbols-alist
        (cons
         '("^." . "⌾")
         haskell-font-lock-symbols-alist)

        haskell-font-lock-symbols-alist
        (cons
         '("<>" . "⊕")
         haskell-font-lock-symbols-alist)

        haskell-font-lock-symbols-alist
        (cons
         '("->" . "⟶")
         haskell-font-lock-symbols-alist)

        haskell-font-lock-symbols-alist
        (cons
         '("<-" . "⟵")
         haskell-font-lock-symbols-alist)

        haskell-font-lock-symbols t

        haskell-process-use-presentation-mode t

        haskell-interactive-mode-scroll-to-bottom t

        haskell-process-type 'cabal-repl))

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

(use-package dante
  :after (haskell-mode)
  :commands 'dante-mode
  :hook  (haskell-mode . dante-mode)
  :init
  (setq dante-tap-type-time 1)
  :config
  (general-add-hook 'dante-mode-hook
                    (list
                     '(lambda ()
                        (flycheck-add-next-checker
                         'haskell-dante
                         '(info . haskell-hlint)))
                     '(lambda ()
                        (eldoc-mode -1)))))

(use-package attrap
  :after (dante))

(general-def 'normal haskell-mode-map
  [remap empty-mode-leader] #'hydra-haskell/body)

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

(provide 'config/langs/haskell)

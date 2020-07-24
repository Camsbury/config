

(-map 'require
      '(langs/alda-conf
        langs/agda-conf
        langs/c-conf
        langs/clisp-conf
        langs/clj-conf
        langs/elisp-conf
        langs/elixir-conf
        langs/env-conf
        langs/go-conf
        langs/haskell-conf
        langs/html-conf
        langs/idris-conf
        langs/js-conf
        langs/lisp-conf
        langs/nix-conf
        langs/python-conf
        langs/racket-conf
        langs/rlang-conf
        langs/rust-conf
        langs/shell-conf))

(use-package dockerfile-mode)
(use-package yaml-mode
  :init (general-add-hook 'yaml-mode-hook
                          (list 'linum-mode)))

(provide 'lang-conf)

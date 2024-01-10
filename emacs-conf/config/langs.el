(require 'prelude)
(-map 'require
      '(config/langs/alda
        config/langs/agda
        config/langs/c
        config/langs/clisp
        config/langs/clj
        config/langs/dockerfile
        config/langs/elisp
        config/langs/elixir
        config/langs/env
        config/langs/go
        config/langs/haskell
        config/langs/html
        config/langs/idris
        config/langs/js
        config/langs/lisp
        config/langs/nix
        config/langs/org
        config/langs/python
        config/langs/racket
        config/langs/rlang
        config/langs/rust
        config/langs/scala
        config/langs/shell
        config/langs/sql
        config/langs/ts
        config/langs/yaml))

(provide 'config/langs)

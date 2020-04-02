(require 'dash)

(when (load "private-conf.el")
  (require 'private-conf))

(-map 'require
      '( buffer-move
         dockerfile-mode
         wgrep

         alda-conf
         agda-conf
         autocomplete-conf
         behavior-conf
         bindings-conf
         browser-conf
         c-conf
         clisp-conf
         clj-conf
         counsel-conf
         dashboard-conf
         docs-conf
         elisp-conf
         elixir-conf
         env-conf
         epub-conf
         evil-conf
         functions-conf
         git-conf
         go-conf
         haskell-conf
         html-conf
         irc-conf
         js-conf
         lisp-conf
         lsp-conf
         merge-conf
         minibuffer-conf
         nix-conf
         org-conf
         package-conf
         pdf-conf
         project-conf
         python-conf
         racket-conf
         rlang-conf
         rust-conf
         scroll-conf
         search-conf
         shell-conf
         ;; slack-conf
         snippet-conf
         style-conf
         theme-conf
         ui-conf

         modes))


(provide 'config)

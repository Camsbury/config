(require 'dash)
(-map 'require
      '( dockerfile-mode
         wgrep

         agda-conf
         autocomplete-conf
         bindings-conf
         c-conf
         counsel-conf
         docs-conf
         elisp-conf
         evil-conf
         functions-conf
         git-conf
         haskell-conf
         lisp-conf
         lsp-conf
         minibuffer-conf
         org-conf
         project-conf
         scroll-conf
         search-conf
         shell-conf
         snippet-conf
         style-conf
         theme-conf
         ui-conf

         modes
         ))


(provide 'config)

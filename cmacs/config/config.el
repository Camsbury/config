(require 'dash)
(-map 'require
      '( dockerfile-mode
         wgrep
         buffer-move

         autocomplete-conf
         bindings-conf
         c-conf
         clj-conf
         counsel-conf
         docs-conf
         elisp-conf
         evil-conf
         functions-conf
         git-conf
         haskell-conf
         hydra-conf
         js-conf
         lisp-conf
         lsp-conf
         minibuffer-conf
         org-conf
         package-conf
         project-conf
         python-conf
         racket-conf
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

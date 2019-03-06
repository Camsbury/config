(require 'dash)
(when (load "private-conf.el")
  (require 'private-conf))

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
         error-conf
         evil-conf
         functions-conf
         git-conf
         haskell-conf
         js-conf
         lisp-conf
         lsp-conf
         merge-conf
         minibuffer-conf
         org-conf
         package-conf
         project-conf
         python-conf
         racket-conf
         scroll-conf
         search-conf
         shell-conf
         slack-conf
         snippet-conf
         style-conf
         theme-conf
         ui-conf

         modes
         ))


(provide 'config)

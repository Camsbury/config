(require 'dash)
(when (load "private-conf.el")
  (require 'private-conf))

(-map 'require
      '( buffer-move
         dockerfile-mode
         wgrep

         autocomplete-conf
         bindings-conf
         browser-conf
         c-conf
         clj-conf
         counsel-conf
         dashboard-conf
         docs-conf
         elisp-conf
         evil-conf
         functions-conf
         git-conf
         haskell-conf
         irc-conf
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
         ;; slack-conf
         snippet-conf
         style-conf
         theme-conf
         ui-conf

         modes))


(provide 'config)

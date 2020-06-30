(require 'dash)

(when (load "private-conf.el")
  (require 'private-conf))

(-map 'require
      '(buffer-move
        dockerfile-mode
        wgrep

        autocomplete-conf
        behavior-conf
        bindings-conf
        browser-conf
        counsel-conf
        dashboard-conf
        ;; dired-conf
        docs-conf
        email-conf
        epub-conf
        evil-conf
        functions-conf
        git-conf
        irc-conf
        lang-conf
        lsp-conf
        merge-conf
        minibuffer-conf
        mode-conf
        org-conf
        package-conf
        pdf-conf
        project-conf
        scroll-conf
        search-conf
        ;; slack-conf
        snippet-conf
        style-conf
        theme-conf
        tractsoft-conf
        ui-conf))


(provide 'config)

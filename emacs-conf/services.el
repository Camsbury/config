(-map 'require
      '(services/docker
        services/email
        services/irc
        services/lsp
        services/radio
        services/spotify))

(provide 'services)

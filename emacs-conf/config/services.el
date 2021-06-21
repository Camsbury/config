(-map 'require
      '(config/services/docker
        config/services/email
        config/services/feeds
        config/services/irc
        config/services/lsp
        config/services/radio
        config/services/spotify))

(provide 'config/services)

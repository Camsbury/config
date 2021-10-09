(require 'prelude)

(m-require config/services
  docker
  email
  feeds
  irc
  lsp
  radio
  spotify)

(provide 'config/services)

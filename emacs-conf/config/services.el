(require 'prelude)

(m-require config/services
  docker
  email
  feeds
  irc
  lastpass
  lsp
  radio
  spotify
  tmux)

(provide 'config/services)

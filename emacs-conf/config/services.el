(require 'prelude)

(m-require config/services
  docker
  email
  feeds
  irc
  lastpass
  lsp
  notifications
  radio
  spotify
  tmux)

(provide 'config/services)

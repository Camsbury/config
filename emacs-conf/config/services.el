(require 'prelude)

(m-require config/services
  eca
  docker
  email
  feeds
  irc
  lsp
  notifications
  radio
  spotify
  tmux)

(provide 'config/services)

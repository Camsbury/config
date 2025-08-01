(require 'prelude)

(m-require config/services
  aider
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

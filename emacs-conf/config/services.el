;; -*- lexical-binding: t; -*-
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
  server
  spotify
  tmux)

(provide 'config/services)

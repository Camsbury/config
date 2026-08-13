;; -*- lexical-binding: t; -*-
(require 'prelude)

(m-require config
  performance
  transient-defaults
  theme
  search
  ;; After `search': the floating-prompt layer shares the cover machinery with
  ;; vertico-posframe and reads its faces and sizing.
  prompts
  navigation
  env
  text
  prog
  info
  desktop
  dev
  langs
  modes
  services
  viewers
  games
  gtd)

(provide 'config)

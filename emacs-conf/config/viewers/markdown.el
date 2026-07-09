;; -*- lexical-binding: t; -*-
(require 'config/desktop/commands)

(use-package grip-mode)
(setq grip-command 'go-grip)
(setq grip-preview-in-webkit nil)
(setq grip-real-time-refresh nil)

(provide 'config/viewers/markdown)

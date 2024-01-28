;; FIXME: the required binaries don't exist for this to work
(use-package markdown-preview-eww)
(use-package markdown-preview-mode)
(setq markdown-command "pandoc")

(provide 'config/viewers/markdown)

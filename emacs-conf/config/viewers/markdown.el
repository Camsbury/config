;; -*- lexical-binding: t; -*-
(require 'config/desktop/commands)
(use-package markdown-preview-eww)
(use-package markdown-preview-mode)
(setq markdown-command "pandoc")

(defun ck/watch-this-markdown ()
  (interactive)
  (async-shell-command
   (concat
    "livedown start "
    (buffer-file-name)
    " --open --browser \"'firefox'\"")
   (generate-new-buffer-name (concat "*Watching " (buffer-file-name) "*"))))

(provide 'config/viewers/markdown)

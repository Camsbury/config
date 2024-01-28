(require 'config/desktop/commands)
(use-package markdown-preview-eww)
(use-package markdown-preview-mode)
(setq markdown-command "pandoc")

(defun watch-this-markdown ()
  (interactive)
  (async-shell-command
   (concat
    "livedown start "
    (buffer-file-name)
    " --open --browser \"'Brave-browser'\"")
   (generate-new-buffer-name (concat "*Watching " (buffer-file-name) "*"))))

(provide 'config/viewers/markdown)

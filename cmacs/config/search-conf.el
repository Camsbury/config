(require 'wgrep)
(require 'avy)

(defun wgrep-save-and-quit ()
  "things"
  (interactive)
  (wgrep-finish-edit)
  (wgrep-save-all-buffers)
  (quit-window))

(general-define-key :keymaps 'wgrep-mode-map
  [remap evil-save-modified-and-close] #'wgrep-save-and-quit)

(provide 'search-conf)

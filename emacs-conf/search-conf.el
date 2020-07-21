(use-package wgrep)
(use-package avy)
(use-package dumb-jump)

(defun wgrep-save-and-quit ()
  "things"
  (interactive)
  (wgrep-finish-edit)
  (wgrep-save-all-buffers)
  (quit-window))

(setq counsel-rg-base-command
      "rg -S -g !'*.lock' -g !.git -g !node_modules -g !yarn --no-heading --line-number --hidden --color never %s .")
(general-define-key :keymaps 'wgrep-mode-map
  [remap evil-save-modified-and-close] #'wgrep-save-and-quit)

(setq dumb-jump-selector 'ivy)
(setq dumb-jump-prefer-searcher 'rg)

(provide 'search-conf)

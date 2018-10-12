(general-add-hook 'magit-mode-hook
                  (list 'evil-magit-init))


(general-define-key
 :states  'normal
 :keymaps 'magit-blame-mode-map
 "q" 'magit-blame-quit)

(provide 'git-conf)

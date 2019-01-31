(general-add-hook 'magit-mode-hook
                  (list 'evil-magit-init))


(general-define-key
 :states  'normal
 :keymaps 'magit-blame-mode-map
 "q" #'magit-blame-quit)

(general-define-key
 :keymaps 'git-timemachine-mode-map
 [remap evil-record-macro] #'git-timemachine-quit
 [remap evil-window-up] #'git-timemachine-show-previous-revision
 [remap evil-window-down] #'git-timemachine-show-next-revision)

(general-define-key
 :states  'normal
 :keymaps 'magit-diff-mode-map
 "zz" #'evil-scroll-line-to-center
 "zt" #'evil-scroll-line-to-top
 "zb" #'evil-scroll-line-to-bottom
 "L"  #'evil-window-bottom
 "H"  #'evil-window-top
 )


(provide 'git-conf)

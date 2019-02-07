(general-add-hook 'magit-mode-hook
                  (list 'evil-magit-init))


(general-define-key
 :states  'normal
 :keymaps 'magit-blame-mode-map
 "q" #'magit-blame-quit)

(general-define-key
 :states  'normal
 :keymaps 'magit-status-mode-map
 [remap magit-section-backward]  #'evil-window-up
 [remap magit-section-forward]   #'evil-window-down
 [remap indent-new-comment-line] #'magit-section-forward
 [remap kill-sentence]           #'magit-section-backward)

(general-define-key
 :keymaps 'git-timemachine-mode-map
 [remap evil-record-macro] #'git-timemachine-quit
 [remap evil-window-up]    #'git-timemachine-show-previous-revision
 [remap evil-window-down]  #'git-timemachine-show-next-revision)

(general-define-key
 :states  'normal
 :keymaps 'magit-diff-mode-map
 "<RET>"                         #'magit-diff-visit-file-other-window
 "zz"                            #'evil-scroll-line-to-center
 "zt"                            #'evil-scroll-line-to-top
 "zb"                            #'evil-scroll-line-to-bottom
 "L"                             #'evil-window-bottom
 "H"                             #'evil-window-top
 [remap magit-section-backward]  #'evil-window-up
 [remap magit-section-forward]   #'evil-window-down
 [remap indent-new-comment-line] #'magit-section-forward
 [remap kill-sentence]           #'magit-section-backward
 [remap scroll-up]               #'hydra-leader-body
 )


(provide 'git-conf)

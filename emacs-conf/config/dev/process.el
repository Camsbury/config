(use-package prodigy
  :config
  (general-def prodigy-mode-map
    [remap evil-goto-line]         #'prodigy-jump-magit
    [remap evil-substitute]        #'prodigy-start
    [remap evil-replace]           #'prodigy-restart
    [remap evil-set-marker]        #'prodigy-mark
    [remap evil-window-middle]     #'prodigy-mark-all
    [remap evil-undo]              #'prodigy-unmark
    [remap evil-ret]               #'prodigy-display-process
    [remap undo-tree-visualize]    #'prodigy-unmark-all
    [remap evil-change-whole-line] #'prodigy-stop))

(provide 'config/dev/process)

(general-define-key
 :keymaps 'doc-view-mode-map
 [remap doc-view-scroll-up-or-next-page] #'hydra-leader/body
 [remap describe-mode] #'doc-view-previous-page
 "k"                   #'doc-view-previous-page
 "l"                   #'doc-view-next-page
 "n"                   #'doc-view-search-next-match
 "p"                   #'doc-view-search-previous-match
 "/"                   #'doc-view-search)

(provide 'pdf-conf)

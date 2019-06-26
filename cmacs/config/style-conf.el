(setq c-basic-indent 2)
(setq c-default-style "linux")
(setq tab-width 2)
(setq-default indent-tabs-mode nil)
(setq-default fill-column 80)
;; Attempt to wrap at 80 in visual-line-mode - currently blocks nice resizing
;; (setq visual-fill-column-fringes-outside-margins nil)
;; (add-hook 'visual-line-mode-hook #'visual-fill-column-mode)
(general-add-hook 'before-save-hook 'whitespace-cleanup)

(provide 'style-conf)

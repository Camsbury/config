(setq c-basic-indent 2)
(setq c-default-style "linux")
(setq tab-width 2)
(setq-default indent-tabs-mode nil)
(setq-default fill-column 80)
(add-hook 'before-save-hook 'whitespace-cleanup)

(provide 'style-conf)

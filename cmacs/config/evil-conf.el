(general-add-hook 'evil-mode-hook
                  (list 'evil-surround-mode
                        'evil-commentary-mode
                        ))

;; Yanks to end instead of whole line
(setq evil-want-Y-yank-to-eol t)

(provide 'evil-conf)

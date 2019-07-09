(general-add-hook 'evil-mode-hook
                  (list 'evil-surround-mode
                        'evil-commentary-mode
                        'evil-visualstar-mode
                        ))

;; Yanks to end instead of whole line
(setq evil-want-Y-yank-to-eol t)
(setq evil-move-beyond-eol t)

(evil-mode)

(provide 'evil-conf)

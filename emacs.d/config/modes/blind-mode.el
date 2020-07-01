(setq blind-mode-on nil)
(setq blind-mode-font-height 100)

(define-minor-mode blind-mode
  "Make it so blind people can see"
  :lighter " blind"
  :global t
  :after-hook (progn
                (if blind-mode-on
                    (progn
                      (setq blind-mode-on nil)
                      (set-face-attribute
                       'default nil :height normal-font-height))
                  (progn
                    (setq blind-mode-on t)
                    (set-face-attribute
                     'default nil :height blind-mode-font-height)))))

(provide 'modes/blind-mode)

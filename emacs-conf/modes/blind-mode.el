(setq blind-mode-font-height 130)

(define-minor-mode blind-mode
  "Make it so blind people can see"
  :lighter " blind"
  :global t
  :after-hook
  (if (minor-mode-active-p 'blind-mode)
      (set-face-attribute
       'default nil :height blind-mode-font-height)
    (set-face-attribute
     'default nil :height normal-font-height)))

(provide 'modes/blind-mode)

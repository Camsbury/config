;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'lib/utils)
(declare-vars normal-font-height)   ; config/theme.el

(defvar blind-mode-font-height 150)

(define-minor-mode blind-mode
  "Make it so blind people can see"
  :lighter " blind"
  :group 'convenience
  :global t
  :after-hook
  (if (ck/minor-mode-active-p 'blind-mode)
      (set-face-attribute
       'default nil :height blind-mode-font-height)
    (set-face-attribute
     'default nil :height normal-font-height)))

(provide 'config/modes/blind-mode)

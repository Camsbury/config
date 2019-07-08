(use-package bindings-conf)

(general-emacs-define-key ivy-minibuffer-map
  [escape] 'minibuffer-keyboard-quit
  )

(provide 'minibuffer-conf)

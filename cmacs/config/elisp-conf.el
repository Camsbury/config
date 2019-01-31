(require 'bindings-conf)
(require 'dash)
(require 'dash-functional)
(require 'f)
(require 's)

(general-add-hook 'emacs-lisp-mode-hook
  (list 'paredit-mode))

(provide 'elisp-conf)

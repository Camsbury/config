(require 'bindings-conf)

(require 'dash)
(require 'dash-functional)
(require 'f)
(require 's)

(general-evil-define-key 'normal lisp-interaction-mode-map
  [remap eval-print-last-sexp] 'evil-window-down)

(general-add-hook 'emacs-lisp-mode-hook
                  (list 'rainbow-delimiters-mode))

(provide 'elisp-conf)

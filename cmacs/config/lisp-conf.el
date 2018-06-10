(require 'bindings-conf)

(general-evil-define-key 'normal lisp-interaction-mode-map
  [remap eval-print-last-sexp] 'evil-window-down)

(general-define-key :keymaps 'paredit-mode-map
  "C-h" 'evil-window-left
  "C-j" 'evil-window-down
  "C-k" 'evil-window-up
  "C-l" 'evil-window-right
  "M-t" 'paredit-forward
  "M-p" 'paredit-forward-up
  "M-v" 'paredit-forward-down
  "M-a" 'paredit-backward
  "M-q" 'paredit-backward-up
  "M-z" 'paredit-backward-down
  "M-r" 'paredit-forward-slurp-sexp
  "M-s" 'paredit-forward-barf-sexp)

(provide 'lisp-conf)

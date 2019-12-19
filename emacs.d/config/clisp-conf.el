(require 'bindings-conf)
(require 'evil)
(require 'lisp-conf)

(setq inferior-lisp-program "nix-shell -p sbcl --run sbcl")


(general-def 'normal lisp-mode-map
 [remap empty-mode-leader] #'hydra-clisp/body)

(defhydra hydra-clisp (:exit t)
  "clisp-mode"
  ("s" #'slime "start slime")
  ("E" #'slime-eval-buffer "eval buffer"))

(nmap :states 'normal :keymaps 'lisp-mode-map
  "M-<RET>" #'slime-eval-defun
  "M-h"     #'paredit-backward-up
  "M-j"     #'lisp-tree-forward
  "M-k"     #'paredit-backward
  "M-l"     #'paredit-forward-down)

(provide 'clisp-conf)

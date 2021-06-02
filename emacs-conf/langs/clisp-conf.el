(use-package evil)
(use-package langs/lisp-conf)
(use-package slime)

(setq inferior-lisp-program "nix-shell -p sbcl --run sbcl")

(general-add-hook 'lisp-mode-hook
                  (list 'paredit-mode
                        'lispyville-mode))

(general-def 'normal lisp-mode-map
 [remap empty-mode-leader] #'hydra-clisp/body)

(defhydra hydra-clisp (:exit t)
  "clisp-mode"
  ("d" #'slime-edit-definition "jump to def")
  ("s" #'slime "start slime")
  ("E" #'slime-eval-buffer "eval buffer"))

(nmap :states 'normal :keymaps 'lisp-mode-map
  "M-<RET>" #'slime-eval-defun)

(provide 'langs/clisp-conf)

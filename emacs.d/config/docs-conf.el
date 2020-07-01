(use-package hydra)
(use-package bindings-conf)
(setq helm-dash-common-docsets '("C" "Emacs Lisp" "Haskell" "HTML" "JavaScript" "Python 3" "React" "Rust"))


(general-def Info-mode-map
  [remap Info-history] 'ignore)

(general-def 'Info-mode-map
  [remap Info-scroll-up] #'hydra-leader/body
  [remap Info-history]   #'evil-window-bottom)

(provide 'docs-conf)

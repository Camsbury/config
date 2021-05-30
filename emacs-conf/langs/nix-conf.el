(use-package nix-mode
  :mode "\\.nix\\'")
(use-package nix-update
  :after (nix-mode))

(general-def 'normal nix-mode-map
 [remap empty-mode-leader] #'hydra-nix/body)

(defhydra hydra-nix (:exit t)
  "nix-mode"
 ("f" #'nix-update-fetch "fetch correct SHA"))

(provide 'langs/nix-conf)

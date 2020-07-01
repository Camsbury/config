(use-package nix-update)
(use-package bindings-conf)

(general-def 'normal nix-mode-map
 [remap empty-mode-leader] #'hydra-nix/body)

(defhydra hydra-nix (:exit t)
  "wnix-mode"
 ("f" #'nix-update-fetch "fetch correct SHA"))

(provide 'langs/nix-conf)

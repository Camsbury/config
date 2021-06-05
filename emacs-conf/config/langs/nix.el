(use-package nix-mode
  :mode "\\.nix\\'")
;; CLEAN: maybe don't need
(add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-mode))
(use-package nix-update
  :after (nix-mode))

(general-def 'normal nix-mode-map
 [remap empty-mode-leader] #'hydra-nix/body)

(defhydra hydra-nix (:exit t)
  "nix-mode"
 ("f" #'nix-update-fetch "fetch correct SHA"))

(provide 'config/langs/nix)

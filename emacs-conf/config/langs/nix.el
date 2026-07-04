;; -*- lexical-binding: t; -*-
(use-package nix-mode
  :mode "\\.nix\\'")
;; CLEAN: maybe don't need
(add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-mode))
(use-package nix-update
  :after (nix-mode))

;; Treesitter nix formatting - TODO: need some nixpkgs and such...
;; (setq treesit-language-source-alist
;;       '((nix . ("https://github.com/nix-community/tree-sitter-nix"))))

(general-def 'normal nix-mode-map
  [remap ck/empty-mode-leader] #'hydra-nix/body)

(defhydra hydra-nix (:exit t)
  "nix-mode"
  ("f" #'nix-update-fetch "fetch correct SHA")
  ("F" #'ck/update-nix-fetchgit "update to latest fetch SHAs, unless #pin"))

(defun ck/update-nix-fetchgit ()
  "Update all fetch shas in the current nix file"
  (interactive)
  (shell-command
   (format "update-nix-fetchgit %s"
           (shell-quote-argument (buffer-file-name)))))

(provide 'config/langs/nix)



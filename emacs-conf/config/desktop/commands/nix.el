;; -*- lexical-binding: t; -*-
(require 'prelude)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Nix / NixOS

(defun ck/nixos-man ()
  (interactive)
  (man "configuration.nix"))

(defun ck/nix-channel-update ()
  "Rebuild nixos"
  (interactive)
  (let ((default-directory "/sudo::"))
    (async-shell-command
     "nix-channel --update"
     (generate-new-buffer-name "*Nix Update Channels*"))))

(defun ck/nixos-channel-version ()
  "Get the nixos channel version"
  (interactive)
  (kill-new
   ;; (shell-command-to-string "nix-instantiate --eval -E '(import <nixos> {}).lib.version'")
   (shell-command-to-string "cat /nix/var/nix/profiles/per-user/root/channels/nixos/svn-revision")))

(defun ck/nixpkgs-channel-version ()
  "Get the nixpkgs channel version"
  (interactive)
  (kill-new
   ;; (shell-command-to-string "nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version'")
   (shell-command-to-string "cat /nix/var/nix/profiles/per-user/root/channels/nixpkgs/svn-revision")))

(defun ck/nixos-rebuild-switch ()
  "Rebuild nixos"
  (interactive)
  (let ((default-directory "/sudo::"))
    (async-shell-command
     "nixos-rebuild switch"
     (generate-new-buffer-name "*NixOS Rebuild Switch*"))))

(defun ck/nix-search (pkg)
  "search nixpkgs for pkg"
  (interactive "sPackage: ")
  (async-shell-command
   (concat "nix --quiet --log-format raw search nixpkgs "
           pkg
           " --json \\\n | jq -r '\n     to_entries[]\n     | \"\\(.value.pname) (\\(.value.version)) - \\(.value.description)\"'")

   (generate-new-buffer-name (concat "*Searching for package: " pkg "*"))))

(defun ck/nixos-option (option)
  "Determine attributes of an option in current nixos expression"
  (interactive "sOption: ")
  (async-shell-command
   (concat "nixos-option " option)
   (generate-new-buffer-name (concat  "*Describing Option: " option "*"))))

(defun ck/ergodox-build-and-flash ()
  "Rebuild ergodox"
  (interactive)
  (let ((default-directory "/sudo::"))
    (async-shell-command
     (concat
      "nix-shell /home/"
      (user-login-name)
      "/projects/Camsbury/config/camerak/shell.nix --run exit")
     (generate-new-buffer-name "*Build and Flash Ergodox*"))))

(defun ck/nix-collect-garbage ()
  "Collect garbage"
  (interactive)
  (async-shell-command
   "nix-collect-garbage -d"
   (generate-new-buffer-name "*Nix Collect Garbage*")))

(defun ck/nix-derivation-is-cached? (derivation)
  "Sees if the derivation is cached on the nixos cache"
  (interactive "sDerivation Path: ")
  (shell-command
   (concat
    "nix path-info -r "
    derivation
    " --store https://cache.nixos.org/")))

(provide 'config/desktop/commands/nix)

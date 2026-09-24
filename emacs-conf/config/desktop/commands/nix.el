;; -*- lexical-binding: t; -*-
(require 'prelude)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Nix / NixOS

(defun ck/nixos-man ()
  (interactive)
  (man "configuration.nix"))

(defun ck/nixos-revision ()
  "Copy the nixpkgs revision the running system was built from."
  (interactive)
  (kill-new
   (string-trim (shell-command-to-string "nixos-version --revision"))))

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
  "Print the value of OPTION in the system built from system.nix.
Evaluates /etc/nixos/system.nix, which passes the npins `sources' the
modules need; `nixos-option' goes through <nixpkgs/nixos> and cannot."
  (interactive "sOption: ")
  (async-shell-command
   (concat "nix eval -f /etc/nixos/system.nix "
           (shell-quote-argument (concat "config." option)))
   (generate-new-buffer-name (concat "*Describing Option: " option "*"))))

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

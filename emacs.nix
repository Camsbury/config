# Emacs packages managed by Nix

{ pkgs ? import <nixpkgs> {} }:

let
  camEmacs = pkgs.emacs;
  emacsWithPackages = (pkgs.emacsPackagesNgGen camEmacs).emacsWithPackages;
in
  emacsWithPackages (epkgs: (with epkgs.melpaStablePackages; [
    counsel
    counsel-projectile
    dash
    define-word
    doom-themes
    evil
    evil-commentary
    evil-magit
    evil-surround
    f
    flycheck
    flycheck-haskell
    flycheck-irony
    flycheck-popup-tip
    git-timemachine
    intero
    ivy
    magit
    mediawiki
    nix-mode
    org-bullets
    projectile
    rainbow-delimiters
    rainbow-identifiers
    restart-emacs
    s
    use-package
  ]) ++ (with epkgs.melpaPackages; [
    command-log-mode
    general
    undo-tree
  ]))

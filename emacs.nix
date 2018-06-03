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
    dash-functional
    define-word
    doom-themes
    evil
    evil-commentary
    evil-magit
    evil-multiedit
    evil-surround
    f
    flycheck
    flycheck-haskell
    flycheck-irony
    flycheck-popup-tip
    git-timemachine
    intero
    irony
    ivy
    magit
    mediawiki
    nix-mode
    nov
    org-bullets
    projectile
    rainbow-delimiters
    rainbow-identifiers
    restart-emacs
    s
    smex
    use-package
  ]) ++ (with epkgs.melpaPackages; [
    command-log-mode
    general
    irony-eldoc
    undo-tree
  ]))

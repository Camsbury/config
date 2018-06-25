# Emacs packages managed by Nix

{ pkgs ? import <nixpkgs> {} }:

let
  camEmacs = pkgs.emacs;
  emacsWithPackages = (pkgs.emacsPackagesNgGen camEmacs).emacsWithPackages;
in
  emacsWithPackages (epkgs: (with epkgs.melpaStablePackages; [
    company
    company-cabal
    company-ghc
    counsel
    counsel-projectile
    dante
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
    # git-timemachine
    helm-dash
    irony
    ivy
    magit
    mediawiki
    nix-mode
    nov
    org-bullets
    paredit
    projectile
    rainbow-delimiters
    rainbow-identifiers
    restart-emacs
    s
    smex
    use-package
    yaml-mode
  ]) ++ (with epkgs.melpaPackages; [
    command-log-mode
    general
    hlint-refactor
    irony-eldoc
    lsp-haskell
    lsp-mode
    lsp-ui
  ]) ++ (with epkgs.elpaPackages; [
    undo-tree
  ]))

# Emacs packages managed by Nix

{ pkgs ? import <nixpkgs> {} }:

let
  emacsWithPackages = (pkgs.emacsPackagesNgGen pkgs.emacs).emacsWithPackages;
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
    dockerfile-mode
    doom-themes
    evil
    evil-commentary
    evil-multiedit
    evil-surround
    evil-visualstar
    f
    flycheck
    flycheck-haskell
    flycheck-irony
    flycheck-popup-tip
    git-timemachine
    helm-dash
    hl-todo
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
    wgrep
    yaml-mode
  ]) ++ (with epkgs.melpaPackages; [
    command-log-mode
    evil-magit
    general
    hlint-refactor
    irony-eldoc
    lsp-haskell
    lsp-mode
    lsp-ui
  ]) ++ (with epkgs.elpaPackages; [
    undo-tree
  ]) ++ (with epkgs; [
    agda2-mode
  ]))

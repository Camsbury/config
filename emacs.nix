# Emacs packages managed by Nix

{ pkgs ? import <nixpkgs> {} }:

let
  emacsWithPackages = (pkgs.emacsPackagesNgGen pkgs.emacs).emacsWithPackages;
  machine = import ./machine.nix;
in
  emacsWithPackages (epkgs: (with epkgs.melpaStablePackages; [
    avy
    buffer-move
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
    exec-path-from-shell
    f
    flycheck
    flycheck-haskell
    flycheck-irony
    flycheck-popup-tip
    git-timemachine
    helm-dash
    hl-todo
    hydra
    irony
    ivy
    ivy-hydra
    js2-mode
    keychain-environment
    magit
    mediawiki
    nav-flash
    nix-mode
    nov
    org-bullets
    paredit
    projectile
    rainbow-delimiters
    rainbow-identifiers
    restart-emacs
    rjsx-mode
    s
    smex
    use-package
    wgrep
    yaml-mode
    yasnippet
  ]) ++ (with epkgs.melpaPackages; [
    cider
    clj-refactor
    command-log-mode
    evil-magit
    general
    hlint-refactor
    irony-eldoc
    jedi # python-lsp
    lsp-haskell
    lsp-mode
    lsp-ui
    paxedit
    prettier-js
    racket-mode
    ranger
    yapfify # python-lsp
  ]) ++ (with epkgs.elpaPackages; [
    undo-tree
  ]) ++ (with epkgs; [
    # agda2-mode
  ]) ++ (
  if machine.darwin
  then
    [epkgs.melpaPackages.lsp-python] else [])
  )

# Emacs packages managed by Nix

{ pkgs ? import <nixpkgs> {} }:

let
  customEmacsPackages = import ./custom-emacs-packages.nix;
  myEmacs = (pkgs.emacsPackagesNgGen pkgs.emacs).overrideScope (self: super:
    customEmacsPackages pkgs self super
  );
  emacsWithPackages = myEmacs.emacsWithPackages;
  machine = import ./machine.nix;
in
  emacsWithPackages (epkgs: (with epkgs.melpaPackages; [
    avy
    buffer-move
    cider
    clj-refactor
    command-log-mode
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
    evil-magit
    evil-multiedit
    evil-smartparens
    evil-surround
    evil-visualstar
    exec-path-from-shell
    f
    flycheck
    flycheck-haskell
    flycheck-irony
    flycheck-popup-tip
    general
    git-timemachine
    helm-dash
    hl-todo
    hlint-refactor
    hydra
    irony
    irony-eldoc
    ivy
    ivy-hydra
    jedi # python-lsp
    js2-mode
    keychain-environment
    lsp-haskell
    lsp-mode
    lsp-ui
    magit
    mediawiki
    nav-flash
    nix-mode
    nov
    ob-async
    ob-ipython
    org-bullets
    paredit
    paxedit
    prettier-js
    projectile
    racket-mode
    rainbow-delimiters
    rainbow-identifiers
    ranger
    restart-emacs
    rjsx-mode
    s
    slack
    smartparens
    smex
    use-package
    wgrep
    yaml-mode
    yapfify # python-lsp
    yasnippet
  ]) ++ (with epkgs.elpaPackages; [
    rainbow-mode
    undo-tree
  ]) ++ (with epkgs; [
    org-clubhouse
    etymology-of-word
    # agda2-mode
  ]) ++ (
    if machine.darwin
    then [
      epkgs.melpaPackages.lsp-python
    ]
    else [
      epkgs.melpaPackages.doom-modeline
    ]
  ))

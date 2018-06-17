# Emacs packages managed by Nix

{ pkgs ? import <nixpkgs> {} }:

let
  # camEmacs = pkgs.emacs;
  camEmacs = pkgs.stdenv.lib.overrideDerivation pkgs.emacs (
    oldAttrs : {
    version = "26.1";
    src = pkgs.fetchurl {
    url = "https://ftp.gnu.org/pub/gnu/emacs/emacs-26.1.tar.xz";
    sha256 = "0b6k1wq44rc8gkvxhi1bbjxbz3cwg29qbq8mklq2az6p1hjgrx0w";

    }; patches = [];});
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
    git-timemachine
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
    irony-eldoc
    lsp-haskell
    lsp-mode
    lsp-ui
    undo-tree
  ]))

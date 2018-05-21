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
    evil
    evil-magit
    evil-surround
    f
    ivy
    magit
    nix-mode
    projectile
    restart-emacs
    s
  ]) ++ (with epkgs.melpaPackages; [
    general
    undo-tree
  ]))

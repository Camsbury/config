# Emacs packages managed by Nix

{ pkgs ? import <nixpkgs> {} }:

let
  camEmacs = pkgs.emacs;
  emacsWithPackages = (pkgs.emacsPackagesNgGen camEmacs).emacsWithPackages;
in
  emacsWithPackages (epkgs: (with epkgs.melpaStablePackages; [
    counsel
    dash
    evil
    f
    ivy
    nix-mode
    restart-emacs
    s
  ]) ++ (with epkgs.melpaPackages; [
    general
    undo-tree
  ]))

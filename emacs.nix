# Emacs packages managed by Nix

{ pkgs ? import <nixpkgs> {} }:

let
  camEmacs = pkgs.emacs;
  emacsWithPackages = (pkgs.emacsPackagesNgGen camEmacs).emacsWithPackages;
in
  emacsWithPackages (epkgs: (with epkgs.melpaStablePackages; [
    evil
    nix-mode
  ]) ++ (with epkgs.melpaPackages; [
    undo-tree
  ]))

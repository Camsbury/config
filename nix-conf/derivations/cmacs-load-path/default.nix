{ config, pkgs, ... }:

with pkgs;
with builtins;
let
  custom-emacs = emacsPackages.emacsWithPackages (import ../../packages/emacs.nix);
in
pkgs.writeShellScriptBin "cmacs-load-path" ''
  echo "${custom-emacs.deps}/share/emacs/site-lisp"
''

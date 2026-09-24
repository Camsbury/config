{ config, pkgs, ... }:

with pkgs;
with builtins;
let
  custom-emacs = cmacs-emacs;
in
pkgs.writeShellScriptBin "cmacs-load-path" ''
  echo "${custom-emacs.deps}/share/emacs/site-lisp"
''

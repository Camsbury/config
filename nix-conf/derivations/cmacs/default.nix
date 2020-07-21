{ config, pkgs, ... }:

with pkgs;
let
  custom-emacs = emacsPackagesNg.emacsWithPackages (import ../../packages/emacs.nix);
  config-path = ../../../emacs-conf;
in
pkgs.writeShellScriptBin "cmacs" ''
  CONFIG_PATH=${config-path} \
  PATH="${custom-emacs}/bin/emacs:$PATH" \
  EMACSLOADPATH="${custom-emacs.deps}/share/emacs/site-lisp:${config-path}:" \
  exec ${custom-emacs}/bin/emacs --debug-init --no-site-file --no-site-lisp $@
''

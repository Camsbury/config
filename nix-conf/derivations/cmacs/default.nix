{ config, pkgs, ... }:

with pkgs;
with builtins;
let
  custom-emacs = emacsPackagesNg.emacsWithPackages (import ../../packages/emacs.nix);
  config-path = ../../../emacs-conf;
  init-file = ../../../emacs-conf/init.el;
in
pkgs.writeShellScriptBin "cmacs" ''
  CONFIG_PATH=${toString config-path} \
  PATH="${custom-emacs}/bin/emacs:$PATH" \
  EMACS_C_SOURCE_PATH=${pkgs.emacs}/share/emacs/${pkgs.emacs.version}/src \
  EMACSLOADPATH="${custom-emacs.deps}/share/emacs/site-lisp:${toString config-path}:" \
  exec ${custom-emacs}/bin/emacs --debug-init --no-site-file --no-site-lisp \
  --no-init-file --load ${toString init-file} $@
''

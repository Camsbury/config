{ config, pkgs, ... }:

with pkgs;
with builtins;
let
  custom-emacs = emacsPackages.emacsWithPackages (import ../../packages/emacs.nix);
  config-path = ../../../emacs-conf;
  init-file   = ../../../emacs-conf/init.el;

  # directory that contains the compiled GSettings schemas
  gsettingsSchemas =
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
in
pkgs.writeShellScriptBin "cmacs" ''
  set -eu

  export CONFIG_PATH=${toString config-path}
  export PATH="${custom-emacs}/bin:$PATH"
  export EMACS_C_SOURCE_PATH=${pkgs.emacs}/share/emacs/${pkgs.emacs.version}/src
  export EMACSLOADPATH="${custom-emacs.deps}/share/emacs/site-lisp:${toString config-path}:"

  export GSETTINGS_SCHEMA_DIR="${gsettingsSchemas}"
  export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share:${pkgs.glib}/share:''${XDG_DATA_DIRS:-}"

  exec ${custom-emacs}/bin/emacs \
    --debug-init --no-site-file --no-site-lisp \
    --no-init-file --load ${toString init-file} \
    "$@"
''

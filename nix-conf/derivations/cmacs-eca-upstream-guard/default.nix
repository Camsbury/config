# Build-time run of emacs-conf/tools/eca-upstream-guard.el.
#
# The ECA upstream adapter (emacs-conf/config/services/eca/upstream.el)
# wraps private names from the eca-emacs package.  An eca bump that renames
# one breaks the running window manager at runtime.  Running the guard here,
# against the same Emacs and package set the cmacs launcher uses, turns that
# into a failed rebuild instead.  modules/cmacs.nix adds this derivation to
# `system.checks`.
{ pkgs, ... }:

let
  guard = ../../../emacs-conf/tools/eca-upstream-guard.el;
in
pkgs.runCommand "cmacs-eca-upstream-guard"
  {
    # A cheap local check: never worth a substituter query or remote build.
    preferLocalBuild = true;
    allowSubstitutes = false;
  }
  ''
    export EMACSLOADPATH="${pkgs.cmacs-emacs.deps}/share/emacs/site-lisp:"

    if ! ${pkgs.cmacs-emacs}/bin/emacs -Q --batch --load ${guard} \
         > report 2>&1; then
      cat report
      echo "cmacs-eca-upstream-guard: update" \
           "emacs-conf/config/services/eca/upstream.el to match eca" >&2
      exit 1
    fi
    cp report "$out"
  ''

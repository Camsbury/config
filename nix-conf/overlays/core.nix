{ config, pkgs, sources, ... }:

let
  unstablePkgs = import sources.nixpkgs-unstable {
    config = {
      allowUnfree = true;
    };
  };
in
{
  nixpkgs.overlays = [
    (
      self: super:
      with builtins;
      with pkgs;
      {

        alias-tips = callPackage (import ../derivations/alias-tips) { };
        check-low-battery =
          callPackage (import ../derivations/check-low-battery) { };
        cmacs = callPackage (import ../derivations/cmacs) { };
        cmacs-load-path =
          callPackage (import ../derivations/cmacs-load-path) { };
        pgn-extract = callPackage (import ../derivations/pgn-extract) { };
      }
      // (with unstablePkgs; {
        inherit bat;
        inherit discord;
        inherit emacs;
        inherit lmstudio;
        inherit mu;
        inherit netdata;
        inherit ouch;
        inherit spotify;
        emacsPackages =
          unstablePkgs.emacsPackages.overrideScope (
            import ./emacs.nix unstablePkgs
          );
      })
    )
  ];
}

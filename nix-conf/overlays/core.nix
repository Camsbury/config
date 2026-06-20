{ config, pkgs, ... }:

let
  unstablePkgs = import (import ../pins.nix).unstable {
    config = {
      allowUnfree = true;
    };
  };
  spotifyPkgs = import (import ../pins.nix).spotify {
    config = {
      allowUnfree = true;
    };
  };

in
{
  nixpkgs.overlays = [
    (
      self: super:
      {

        alias-tips = with builtins; with pkgs; callPackage (import ../derivations/alias-tips) { };

        check-low-battery =
          with builtins;
          with pkgs;
          callPackage (import ../derivations/check-low-battery) { };

        cmacs = with builtins; with pkgs; callPackage (import ../derivations/cmacs) { };

        cmacs-load-path = with builtins; with pkgs; callPackage (import ../derivations/cmacs-load-path) { };

        gollama = with builtins; with pkgs; callPackage (import ../derivations/gollama) { };

        lmstudio = with builtins; with pkgs; callPackage (import ../derivations/lmstudio) { };

        pgn-extract = with builtins; with pkgs; callPackage (import ../derivations/pgn-extract) { };

        spotify = spotifyPkgs.spotify;

        xndr =
          super.callPackage (builtins.fetchTarball "https://github.com/Camsbury/xndr/archive/094be18.tar.gz")
            { pkgs = self; };

      }
      // (with unstablePkgs; {
        inherit bat;
        inherit emacs;
        inherit mu;
        inherit netdata;
      })
    )
    (import ./emacs.nix)
  ];
}

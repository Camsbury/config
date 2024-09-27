{config, pkgs, ...}:

let
  aldaDer = import ../derivations/alda/default.nix;
  alda = with builtins; with pkgs; callPackage aldaDer {inherit stdenv; inherit fetchurl;};
in
  {
    environment.systemPackages = [
      alda
      pkgs.lmms
    ];
  }

{ config, pkgs, ... }:

# Opt-in: machines import this file directly, and ./default.nix does not.
# Making music: the alda score language and the LMMS studio.
let
  aldaDer = import ../../derivations/alda/default.nix;
  alda =
    with builtins;
    with pkgs;
    callPackage aldaDer {
      inherit stdenv;
      inherit fetchurl;
    };
in
{
  environment.systemPackages = [
    alda
    pkgs.lmms
  ];
}

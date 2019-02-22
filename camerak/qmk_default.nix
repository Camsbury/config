{ nixpkgs ? builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/be445a9074f.tar.gz" }:
let
  pkgs = import nixpkgs {};
in pkgs.pkgsCross.avr.stdenv.mkDerivation rec {
  name = "camerak";
  src = ./.;
  buildFlags = "ergodox_ez:camerak";
  installPhase = "cp *.hex $out";
  phases = [
    "unpackPhase"
    "buildPhase"
    "installPhase"
  ];
}

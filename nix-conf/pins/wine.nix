let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
  wine = (import ../pins.nix).wine;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    rev = wine.rev;
    hash = wine.hash;
  })

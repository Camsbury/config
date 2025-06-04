let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
  spotify = (import ../pins.nix).spotify;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    rev = spotify.rev;
    hash = spotify.hash;
})

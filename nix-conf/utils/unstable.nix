let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
  unstable = (import ../pins.nix).unstable;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    rev = unstable.rev;
    hash = unstable.hash;
})

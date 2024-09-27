let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
  brave = (import ../pins.nix).brave;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    rev = brave.rev;
    hash = brave.hash;
})

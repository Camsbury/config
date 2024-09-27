let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
  hardware = (import ../pins.nix).hardware;
in
  fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixos-hardware";
    rev = hardware.rev;
    hash = hardware.hash;
  }

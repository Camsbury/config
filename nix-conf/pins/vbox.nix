let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
  vbox = (import ../pins.nix).vbox;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    rev = vbox.rev;
    hash = vbox.hash;
  })

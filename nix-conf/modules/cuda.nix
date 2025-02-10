{ config, pkgs, ... }:

let
  pins = import ../pins.nix;
  cudaPkgs = import (
    pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo  = "nixpkgs";
      rev = pins.cuda.rev;
      hash = pins.cuda.hash;
    }
  ) { config = { allowUnfree = true; }; };
in
  {

    hardware.graphics.enable = true;
    # hardware.opengl.setLdLibraryPath = true;

    environment.systemPackages = [
      cudaPkgs.cudatoolkit
    ];
  }

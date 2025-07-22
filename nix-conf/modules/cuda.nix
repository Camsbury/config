{ config, pkgs, ... }:

let
  cudaPkgs = import (import ../pins.nix).cuda {
    config = { allowUnfree = true; };
  };
in
  {
    hardware.graphics.enable = true;
    # hardware.opengl.setLdLibraryPath = true;

    environment.systemPackages = [
      cudaPkgs.cudatoolkit
    ];
  }

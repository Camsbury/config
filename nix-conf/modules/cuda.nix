{ config, pkgs, sources, ... }:

let
  cudaPkgs = import sources.nixpkgs-unstable {
    config = {
      allowUnfree = true;
    };
  };
in
  {
    hardware.graphics.enable = true;
    # hardware.opengl.setLdLibraryPath = true;

    environment.systemPackages = [
      cudaPkgs.cudatoolkit
    ];
  }

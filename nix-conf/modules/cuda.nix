{ config, pkgs, ... }:

{

  hardware.opengl.enable = true;
  hardware.opengl.setLdLibraryPath = true;

  environment.systemPackages = with pkgs; [
    cudatoolkit
  ];
}

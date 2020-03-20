{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nvtop
    steam
  ];

  hardware.opengl.driSupport32Bit = true;
}

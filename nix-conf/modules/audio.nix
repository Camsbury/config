{ config, pkgs, lib, ... }:

{
  environment.systemPackages = [pkgs.pavucontrol];

  nixpkgs.config.pulseaudio = true;

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    # package = pkgs.pulseaudioFull;
  };

  sound.enable = true;
}

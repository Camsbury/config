{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    pavucontrol
    alsa-utils
  ];

  nixpkgs.config.pulseaudio = true;

  services.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
  };


  services.pipewire.enable = false;

  # sound.enable = true;
}

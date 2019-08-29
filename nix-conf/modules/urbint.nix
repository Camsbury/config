{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    google-chrome
    zoom-us
  ];
  networking.firewall.enable = false;
}

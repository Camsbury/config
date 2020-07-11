{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    zoom-us
  ];
  virtualisation.virtualbox.host.enable = true;
}

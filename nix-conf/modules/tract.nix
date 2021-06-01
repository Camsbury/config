{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    zoom-us
    teams
  ];
  virtualisation.virtualbox.host.enable = true;
}

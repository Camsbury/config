{ config, pkgs, lib, ... }:

{
  services.hardware.openrgb.enable = true;

  environment.systemPackages = with pkgs; [ openrgb-with-all-plugins ];
}

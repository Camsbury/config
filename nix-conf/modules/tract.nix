{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    awscli
    zoom-us
  ];
}

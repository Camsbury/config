{ config, pkgs, ... }:

{
  imports = [
    ./exwm.nix
  ];
  environment.systemPackages = with pkgs; [
    cmacs
    cmacs-load-path
  ];
}

{ config, pkgs, ... }:

{
  imports = [
    ./exwm.nix
  ];
  environment.systemPackages = with pkgs; [
    cmacs
    cmacs-load-path
  ];
  # An eca bump that breaks the ECA upstream adapter fails the rebuild.
  system.checks = [ pkgs.cmacs-eca-upstream-guard ];
}

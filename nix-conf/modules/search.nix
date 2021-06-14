{ config, pkgs, ... }:

{
  imports = [
  ];
  environment.systemPackages = with pkgs; [
    ack
    ag
    fd
    lsof
    ripgrep
  ];
}

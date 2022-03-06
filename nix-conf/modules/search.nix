{ config, pkgs, ... }:

{
  imports = [
  ];
  environment.systemPackages = with pkgs; [
    ack
    fd
    lsof
    ripgrep
    silver-searcher
  ];
}

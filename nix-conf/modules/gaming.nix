{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nvtop
    steam
  ];
}

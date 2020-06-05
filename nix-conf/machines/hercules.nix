{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix
    ../modules/xps.nix
    ../modules/music.nix
  ];
}

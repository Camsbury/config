
{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix
    ../modules/intel.nix
    ../modules/music.nix
    ../modules/macbook.nix
    ../modules/laptop.nix
  ];
}


{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix
    ../modules/intel.nix
    ../modules/ssd.nix
    ../modules/music.nix
    ../modules/non-ergodox.nix
    ../modules/macbook.nix
    ../modules/laptop.nix
  ];
}

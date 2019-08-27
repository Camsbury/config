{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix
    ../modules/intel.nix
    ../modules/laptop.nix
    ../modules/ssd.nix
    ../modules/xps.nix
  ];
}

{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix
    ../modules/intel.nix
    ../modules/laptop.nix
    ../modules/non-ergodox.nix
    ../modules/ssd.nix
  ];
}

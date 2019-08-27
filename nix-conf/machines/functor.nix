{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix
    ../modules/gaming.nix
    ../modules/intel.nix
    ../modules/nvidia.nix
    ../modules/ssd.nix
  ];
}

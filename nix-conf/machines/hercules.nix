{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix
    ../modules/xps.nix
    ../modules/urbint.nix
  ];
}

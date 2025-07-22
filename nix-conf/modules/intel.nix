{ config, pkgs, ... }:

{
  imports = [
    "${(import ../pins.nix).hardware}/common/cpu/intel"
  ];
}

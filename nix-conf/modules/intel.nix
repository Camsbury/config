{ config, pkgs, ... }:

{
  imports = [
    "${import ../utils/hardware.nix}/common/cpu/intel"
  ];
}

{ config, pkgs, ... }:

{
  imports = [
    "${import ../utils/hardware.nix}/common/pc/ssd"
  ];
}

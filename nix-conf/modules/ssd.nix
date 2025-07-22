{ config, pkgs, ... }:

{
  imports = [
    "${(import ../pins.nix).hardware}/common/pc/ssd"
  ];
}

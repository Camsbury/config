{ config, pkgs, sources, ... }:

{
  imports = [
    "${sources.nixos-hardware}/common/pc/ssd"
  ];
}

{ config, pkgs, sources, ... }:

{
  imports = [
    "${sources.nixos-hardware}/common/cpu/intel"
  ];
}

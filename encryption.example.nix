# Encrypted drive information for NixOS

{ config, pkgs, ... }:

{
  #path for the encrypted drive
  boot.initrd.luks.devices.crypted.device = "/dev/disk/by-uuid/<FILL-ME-IN>"
}

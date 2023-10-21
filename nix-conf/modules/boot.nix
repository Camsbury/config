{ config, pkgs, lib, ... }:

{
  boot = {
    loader = {
      grub = {
        device = "nodev";
        enable = true;
        efiSupport = true;
      };
      efi.canTouchEfiVariables = true;
    };
  };
}

{ config, pkgs, lib, ... }:

{
  boot = {
    cleanTmpDir = true;
    loader = {
      grub = {
        device = "nodev";
        enable = true;
        efiSupport = true;
        version = 2;
      };
      efi.canTouchEfiVariables = true;
    };
  };
}

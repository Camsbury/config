# Boot Config

{ config, pkgs, ... }:

{
  boot = {
    loader = {
      grub = {
        device = "nodev";
        enable = true;
        efiSupport = true;
        useOSProber = true;
        version = 2;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };
}

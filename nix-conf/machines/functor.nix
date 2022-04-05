{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix

    # hardware
    ../modules/intel.nix
    ../modules/nvidia.nix
    ../modules/ssd.nix
    ../modules/slimblade.nix

    #functionality
    ../modules/android.nix
    ../modules/bluetooth.nix
    ../modules/crypto.nix
    ../modules/cuda.nix
    ../modules/gaming.nix
    ../modules/music.nix
    ../modules/tract.nix
    ../modules/email.nix
    ../modules/htb.nix
  ];

  networking.hostName = "functor";
  users.users.default.name = "monoid";

  system.stateVersion = "20.03";
}

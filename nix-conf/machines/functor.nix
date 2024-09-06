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
    ../modules/art.nix
    ../modules/bluetooth.nix
    ../modules/crypto.nix
    ../modules/cuda.nix
    ../modules/gaming.nix
    ../modules/music.nix
    ../modules/influxdb.nix

    # ../modules/tract.nix
    ../modules/email.nix
    ../modules/htb.nix
    ../modules/razer.nix
    ../modules/foreign.nix
    ../modules/printing.nix
  ];

  networking.hostName = "functor";
  users.users.default.name = "monoid";

  system.stateVersion = "20.03";
}

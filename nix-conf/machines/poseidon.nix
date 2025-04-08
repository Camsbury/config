{ config, pkgs, lib, ... }:

{
  imports = [
    ../modules/core.nix

    # hardware
    ../modules/intel.nix
    ../modules/rtx-5070-ti.nix
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

    ../modules/gen-ai.nix
    # ../modules/email.nix
    # ../modules/htb.nix
    ../modules/razer.nix
    ../modules/foreign.nix
    ../modules/printing.nix
    ../modules/svalboard.nix
  ];

  boot.initrd.luks.devices.crypted.device = "/dev/disk/by-uuid/a5f95eb4-a033-40c9-81a1-4ae489adfc7c";

  networking.hostName = "poseidon";
  users.users.default.name = "camsbury";

  system.stateVersion = "24.11";
}

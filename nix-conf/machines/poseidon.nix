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
    ../modules/rgb.nix

    ../modules/gen-ai.nix
    ../modules/email.nix
    ../modules/virtualization.nix
    ../modules/razer.nix
    ../modules/foreign.nix
    ../modules/printing.nix
    ../modules/svalboard.nix
  ];

  services.xserver.screenSection = ''
      Option "MetaModes" "DPY-1: 3840x2160_240 +0+0"
    '';

  services.transmission.settings.download-dir = "/mnt/hdd16t/transmission-downloads";

  boot.initrd.luks.devices.crypted.device = "/dev/disk/by-uuid/a5f95eb4-a033-40c9-81a1-4ae489adfc7c";
  boot.initrd.luks.devices.cryptedStore.device = "/dev/disk/by-uuid/77a45769-1398-44bd-a7a4-ebb05bfad2f6";
  boot.initrd.luks.devices.cryptedSSD500G.device = "/dev/disk/by-uuid/88df2045-baed-444d-ad6f-3832d841ee61";
  boot.initrd.luks.devices.cryptedHDD16T.device = "/dev/disk/by-uuid/720ce7b5-e3aa-4b7e-a079-e06c9c3e42a0";

  networking.hostName = "poseidon";
  users.users.default.name = "camsbury";

  system.stateVersion = "24.11";
}

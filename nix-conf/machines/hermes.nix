{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix

    # hardware
    "${import ../utils/hardware.nix}/dell/xps/13-9310"
    ../modules/intel.nix
    ../modules/ssd.nix
    ../modules/laptop.nix
    ../modules/non-ergodox.nix

    #functionality
    ../modules/tract.nix
    ../modules/email.nix
    ../modules/htb.nix
  ];

  boot.initrd.luks.devices.crypted.device = "/dev/disk/by-uuid/559bcebb-ef43-4d84-8550-8b371bfb6aa6";

  networking.hostName = "hermes";
  users.users.default.name = "camsbury";

  services.xserver.xrandrHeads = [
    { output = "eDP-1";
      primary = true;
      monitorConfig = ''
        DisplaySize 406 228
      '';
    }
    { output = "DP-3";
      monitorConfig = ''
        DisplaySize 508 285
      '';
    }
  ];

  hardware.bluetooth.enable = true;

  system.stateVersion = "20.03";
}

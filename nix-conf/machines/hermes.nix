{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix
    ../modules/intel.nix
    ../modules/laptop.nix
    ../modules/non-ergodox.nix
    ../modules/ssd.nix
    ../modules/tract.nix
    "${import ../utils/hardware.nix}/dell/xps/13-9310"
  ];

  boot.initrd.luks.devices.crypted.device = "/dev/disk/by-uuid/559bcebb-ef43-4d84-8550-8b371bfb6aa6";

  networking.hostName = "hermes";

  nix.trustedUsers = [
    "root"
    "camsbury"
  ];

  users.users.camsbury = {
    home = "/home/camsbury";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    isNormalUser = true;
    shell = pkgs.zsh;
  };

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

  home-manager.users.camsbury = import ../modules/home.nix;
}

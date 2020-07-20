{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix
    ../modules/intel.nix
    ../modules/laptop.nix
    ../modules/non-ergodox.nix
    ../modules/ssd.nix
    ../modules/music.nix
  ];

  boot.initrd.luks.devices.crypted.device = "/dev/disk/by-uuid/33edaf89-8028-4432-9489-2bedeedb73df";

  networking.hostName = "feather";

  nix.trustedUsers = [
    "root"
    "quill"
  ];

  users.users.quill = {
    home = "/home/quill";
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
       "docker"
    ];
    shell = pkgs.zsh;
  };
  home-manager.users.quill = import ../modules/home.nix;
}


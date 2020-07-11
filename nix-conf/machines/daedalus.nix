{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix
    ../modules/intel.nix
    ../modules/laptop.nix
    ../modules/non-ergodox.nix
    ../modules/ssd.nix
    ../modules/tract.nix
    ../modules/email.nix
  ];


  boot.initrd.luks.devices = {
    crypted.device = "/dev/disk/by-uuid/62965da1-035a-4592-b061-f51d7caa80f3";
    hcrypted.device = "/dev/disk/by-uuid/6a664a55-a8e6-4411-b09d-e1b3d0ff2d7c";
  };

  networking.hostName = "daedalus";

  nix.trustedUsers = [
    "root"
    "camsbury"
  ];
  users.users.camsbury = {
    home = "/home/camsbury";
    extraGroups = [
      "wheel"
      "docker"
    ];
    isNormalUser = true;
    shell = pkgs.zsh;
  };
  home-manager.users.camsbury = import ../modules/home.nix;
}

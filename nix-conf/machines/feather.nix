{ config, pkgs, ... }:

{
  imports = [
    ../modules/core
    ../modules/hardware/intel-cpu.nix
    ../modules/hardware/intel-graphics.nix
    ../modules/hardware/laptop.nix
    ../modules/hardware/builtin-keyboard.nix
    ../modules/apps/music.nix
  ];

  boot.initrd.luks.devices.crypted.device = "/dev/disk/by-uuid/33edaf89-8028-4432-9489-2bedeedb73df";

  networking.hostName = "feather";
  users.users.default.name = "quill";

  system.stateVersion = "20.03";
}

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

  # Built-in panel mode, used to size the lock screen and greeter wallpaper.
  # UNVERIFIED guess: nobody has read this panel yet. Check it on feather with
  # `xrandr | grep '*'` and correct it. A wrong value only leaves a border on,
  # or crops, those two backgrounds.
  ck.theme.screenResolution = "1920x1080";

  networking.hostName = "feather";
  users.users.default.name = "quill";

  system.stateVersion = "20.03";
}

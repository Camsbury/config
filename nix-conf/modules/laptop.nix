{ config, pkgs, ... }:

{
  imports = [
    "${import ../utils/hardware.nix}/common/pc/laptop"
  ];
  services = {
    xserver.libinput = {
      enable = true;
      touchpad.naturalScrolling = true;
      touchpad.tapping = false;
    };
    upower.enable = true;
  };
}

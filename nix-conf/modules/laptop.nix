{ config, pkgs, ... }:

{
  imports = [
    "${import ../utils/hardware.nix}/common/pc/laptop"
    ./check-battery.nix
  ];
  services = {
    xserver.libinput = {
      enable = true;
      touchpad.naturalScrolling = true;
      touchpad.tapping = false;
    };
    upower.enable = true;
  };
  environment.systemPackages = with pkgs; [
    check-low-battery
  ];
}

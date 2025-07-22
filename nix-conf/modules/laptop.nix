{ config, pkgs, ... }:

{
  imports = [
    "${(import ../pins.nix).hardware}/common/pc/laptop"
    ./check-battery.nix
  ];
  boot.kernelParams = [
    "mem_sleep_default=deep"
  ];
  services = {
    libinput = {
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

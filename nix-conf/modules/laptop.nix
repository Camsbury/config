{ config, pkgs, ... }:

{
  imports = [
    "${import ../utils/hardware.nix}/common/pc/laptop"
  ];
  services = {
    xserver.libinput = {
      enable = true;
      naturalScrolling = true;
      tapping = false;
    };
    upower.enable = true;
    # cron = {
    #   enable = true;
    #   systemCronJobs = {
    #     "***** checkpower"
    #   };
    # };
  };
}

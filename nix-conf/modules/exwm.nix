{ config, pkgs, lib, ... }:

{
  services.xserver = {
    displayManager = {
      sessionCommands = "${pkgs.xorg.xhost}/bin/xhost +SI:localuser:$USER";
      defaultSession = "none+exwm";
    };
    windowManager = {
      session = lib.singleton {
        name = "exwm";
        start = "${pkgs.cmacs}/bin/cmacs";
      };
    };
  };
}

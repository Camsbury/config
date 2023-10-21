{ config, pkgs, ... }:

{
  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xinput}/bin/xinput set-button-map \
    "Kensington Slimblade Trackball" 1 2 3 4 5 0 0 3 && \
    ${pkgs.xorg.xinput}/bin/xinput --set-prop \
    "Kensington Slimblade Trackball" "libinput Accel Speed" 1
  '';
}

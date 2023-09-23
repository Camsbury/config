{ config, pkgs, ... }:

{
  # Assumes Razer is device 9
  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xinput}/bin/xinput set-button-map \
    9 1 2 3 4 5 6 7 0 0 && \
    ${pkgs.xorg.xinput}/bin/xinput --set-prop \
    9 "Device Accel Constant Deceleration" 0.4
  '';
  hardware.openrazer.enable = true;
  users.extraGroups.openrazer.members = [
    "${toString config.users.users.default.name}"
  ];
}

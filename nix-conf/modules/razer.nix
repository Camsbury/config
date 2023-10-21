{ config, pkgs, ... }:

{
  # Assumes Razer is device 9
  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xinput}/bin/xinput set-button-map \
    9 1 2 3 4 5 6 7 0 0 && \
    ${pkgs.xorg.xinput}/bin/xinput --set-prop \
    9 "libinput Accel Speed" 1
  '';
  hardware.openrazer.enable = true;
  users.extraGroups.openrazer.members = [
    "${toString config.users.users.default.name}"
  ];
  environment.systemPackages = [pkgs.razergenie];
}

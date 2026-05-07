{ config, pkgs, ... }:

{
  # Assumes Razer is device 9
  # services.xserver.displayManager.sessionCommands = ''
  #   ${pkgs.xorg.xinput}/bin/xinput set-button-map \
  #   9 1 2 3 4 5 6 7 0 0 && \
  #   ${pkgs.xorg.xinput}/bin/xinput --set-prop \
  #   9 "libinput Accel Speed" 1
  # '';
  services.xserver.inputClassSections = [
    ''
    Identifier   "Razer Razer DeathAdder V2"
    MatchProduct "Razer"
    MatchUSBID     "1532:0084"
    MatchIsPointer "on"
    Driver       "libinput"
    Option       "AccelProfile" "adaptive"
    Option       "AccelSpeed"   "1.0"
    Option       "ButtonMapping" "1 2 3 4 5 6 7 0 0"
    ''
  ];
  hardware.openrazer.enable = true;
  users.extraGroups.openrazer.members = [
    "${toString config.users.users.default.name}"
  ];
  environment.systemPackages = [pkgs.razergenie];
}

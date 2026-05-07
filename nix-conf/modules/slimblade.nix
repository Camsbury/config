{ config, pkgs, ... }:

{
  # services.xserver.displayManager.sessionCommands = ''
  #   ${pkgs.xorg.xinput}/bin/xinput set-button-map \
  #   "Kensington Slimblade Trackball" 1 2 3 4 5 0 0 3 && \
  #   ${pkgs.xorg.xinput}/bin/xinput --set-prop \
  #   "Kensington Slimblade Trackball" "libinput Accel Speed" 1
  # '';

  services.xserver.inputClassSections = [
    ''
    Identifier   "Kensington Slimblade Trackball"
    MatchProduct "Kensington"
    MatchIsPointer "on"
    Driver       "libinput"
    Option       "AccelProfile" "adaptive"
    Option       "AccelSpeed"   "1.0"
    Option       "TransformationMatrix" "2.5 0 0 0 2.5 0 0 0 1"
    Option       "ButtonMapping" "1 2 3 4 5 0 0 3"
    ''
  ];
}

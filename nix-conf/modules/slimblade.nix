{ config, pkgs, ... }:

{
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

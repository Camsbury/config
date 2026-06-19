{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.picom = {
    enable = true;
    backend = "glx";
    vSync = true;
    shadow = false;
    fade = false;
    settings = {
      unredir-if-possible = true; # fullscreen games bypass
      # EXWM's Emacs frame is opaque and covers the whole screen, so picom
      # treats it as a fullscreen window and unredirects. Every dunst
      # notification then forces a re-redirect -> visible black flash on
      # NVIDIA. Excluding the Emacs frame stops that, while real fullscreen
      # games (their own X windows, not class Emacs) still trigger the bypass.
      unredir-if-possible-exclude = [ "class_g = 'Emacs'" ];
    };
  };
}

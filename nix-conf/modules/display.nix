{ config, pkgs, lib, ... }:

{
  services.picom = {
    enable = true;
    backend = "glx";
    vSync = true;
    shadow = false;
    fade = false;
  };
}

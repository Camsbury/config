{ config, pkgs, ... }:

{
  services.xserver = {
    xkb.options = "compose:menu";
  };
}

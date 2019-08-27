{ config, pkgs, ... }:

{
  services.xserver = {
    xkbVariant = "colemak";
    xkbOptions = "caps:escape, altwin:swap_lalt_lwin";
  }
}

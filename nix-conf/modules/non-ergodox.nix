{ config, pkgs, ... }:

{
  services.xserver.xkb = {
    variant = "colemak";
    options = "caps:escape, altwin:swap_lalt_lwin";
  };
}

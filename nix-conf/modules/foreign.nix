{ config, pkgs, ... }:

{
  services.xserver = {
    xkbOptions = "compose:menu";
  };
}

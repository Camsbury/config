{ config, pkgs, ... }:

{
  boot.loader.grub.efiInstallAsRemovable = true;
  services.xserver.xrandrHeads = [{
    output = "eDP-1";
    primary = true;
    monitorConfig = ''
      DisplaySize 406 228
    '';
  }];
}

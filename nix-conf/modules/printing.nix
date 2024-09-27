{ config, pkgs, ... }:

{
  services.printing = {
    enable = true;
    drivers = [pkgs.hplipWithPlugin];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  # Be sure to add printers as root!
  environment.systemPackages = [
    pkgs.system-config-printer
  ];
}

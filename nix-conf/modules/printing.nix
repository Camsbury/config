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
  programs.system-config-printer.enable = true;

  # NOTE: Be sure to add printers as root!
  # ippfind -> get the uri
  # lpstat -t -> get the name
  # sudo lpadmin -p $PRINTER_NAME -E -v $URI -m everywhere
}

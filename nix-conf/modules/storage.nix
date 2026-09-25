{ pkgs, ... }:

# Disks and volumes: mounting removable media, encrypted volumes, and disk
# usage.
{
  services.udisks2.enable = true;

  environment.systemPackages = with pkgs; [
    baobab
    veracrypt
  ];
}

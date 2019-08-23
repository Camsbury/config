# Networking setup for this machine

{ config, pkgs, ...}:

{
  # define your hostname
  networking.hostName = "newMachine";
  # enables wireless support via wpa_supplicant
  # networking.wireless.enable = true;
  # enables wireless support via NetworkManager
  networking.networkmanager.enable = true;

  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.enable = false;
}

{ pkgs, ... }:

# Network connections: NetworkManager, the VPN clients, and the firewall
# policy they need.
{
  networking = {
    networkmanager.enable = true;
    firewall.checkReversePath = false;
  };

  environment.systemPackages = with pkgs; [
    openvpn
    proton-vpn
  ];

  services.netbird.clients.wt0 = {
    port = 51821;
    ui.enable = false; # or true if you want the tray icon
    openFirewall = true;
    openInternalFirewall = true;
  };
}

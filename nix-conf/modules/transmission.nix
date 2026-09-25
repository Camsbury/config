{ config, pkgs, ... }:

# The transmission BitTorrent daemon. A machine may set its own
# services.transmission.settings.download-dir.
{
  services.transmission = {
    enable = true;
    openFirewall = true;
    package = pkgs.transmission_4;
  };

  systemd.tmpfiles.rules = [
    "d ${toString config.services.transmission.settings.download-dir} 0770 transmission transmission - -"
  ];
}

{ config, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      mu
      offlineimap
    ];
    variables = {
      MU_PATH = "${pkgs.mu}";
    };
  };
  systemd.user.services.offlineimap = {
    description = "OfflineIMAP Quicksync";
    path = [ pkgs.gnupg ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.offlineimap}/bin/offlineimap --info -o -q";
    };
  };
  systemd.user.timers.offlineimap = {
    description = "OfflineIMAP Quicksync Timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitInactiveSec = "1m";
    };
  };

 systemd.services.offlineimap.enable = true;
}

{ config, pkgs, ... }:

{
  systemd.user.services.check-low-battery = {
    description = "Notifier";
    path = [ pkgs.libnotify ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''${pkgs.check-low-battery}/bin/check-low-battery'';
    };
  };
  systemd.user.timers.check-low-battery = {
    description = "Notifier Timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitInactiveSec = "1m";
    };
  };

 systemd.user.services.check-low-battery.enable = true;
 systemd.user.timers.check-low-battery.enable = true;
}

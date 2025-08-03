{ config, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      (isync.override { withCyrusSaslXoauth2 = true; }) # sync client
      mu                                                # email client
      msmtp                                             # send/SMTP client
      oauth2l                                           # oauth login
    ];
  };

  systemd.user = {
    services.mbsync = {
      description = "mbsync – sync Maildir";
      after       = [ "network-online.target" ];
      serviceConfig = {
        Type          = "oneshot";
        ExecStart     = "${pkgs.isync}/bin/mbsync -a";
        ExecStartPost = "${pkgs.mu}/bin/mu index";
      };
      wantedBy = [ "default.target" ];
    };
    timers.mbsync = {
      description = "Poll IMAP every 5 min";
      timerConfig = {
        OnBootSec       = "5min";
        OnUnitActiveSec = "5min";
        AccuracySec     = "30s";
      };
      wantedBy = [ "timers.target" ];
    };
  };
}

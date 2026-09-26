{ config, pkgs, ... }:

# Opt-in: machines import this file directly, and ./default.nix does not.
# The mail sync pipeline cmacs reads: isync fetches, mu indexes, msmtp
# sends. A mail client you launch is in the communication section of
# ./default.nix instead.
let
  isyncXoauth2 = pkgs.isync.override { withCyrusSaslXoauth2 = true; };
in
{
  environment = {
    systemPackages = with pkgs; [
      isyncXoauth2 # sync client
      mu # email client
      msmtp # send/SMTP client
      oauth2l # oauth login
    ];
  };

  systemd.user = {
    # No network-online.target ordering: that unit exists only in the
    # system manager, so a user unit cannot wait on it. A sync that runs
    # before the network is up fails, and the next timer tick recovers.
    services.mbsync = {
      description = "mbsync - sync Maildir";
      path = [
        pkgs.oauth2l
        pkgs.mu
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${isyncXoauth2}/bin/mbsync -a";
        # The script sorts mail and runs `mu index` itself, because it
        # must skip indexing while mu4e holds the database lock.
        ExecStartPost = "${pkgs.babashka}/bin/bb ${../../../parse-email.bb}";
      };
      # No wantedBy: the timer alone starts syncs. A oneshot wanted by
      # default.target makes every nixos-rebuild switch wait for a full
      # mail sync.
    };
    timers.mbsync = {
      description = "Poll IMAP every 5 min";
      timerConfig = {
        # Counts from user manager start (login), not from boot.
        OnStartupSec = "1min";
        OnUnitActiveSec = "5min";
        AccuracySec = "30s";
      };
      wantedBy = [ "timers.target" ];
    };
  };
}

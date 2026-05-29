{ config, pkgs, lib, ... }:

{
  services.netdata = {
    config = {
      web = { "bind to" = "127.0.0.1"; };
    };
    enable = true;
    package = pkgs.netdata.override {
      withCloudUi = true;
    };
  };

  systemd.services.syshealth = {
    description = "syshealth — PSI contention snapshotter";
    wantedBy = [ "multi-user.target" ];

    # bb is invoked by absolute path below, so it needn't be on PATH;
    # its CHILDREN do: `top` (procps) and the cat-fallback in slurp-proc (coreutils).
    path = [ pkgs.procps pkgs.coreutils ];

    environment = { THRESH = "30"; WINDOW = "1"; RESNAP = "30"; };

    unitConfig = {
      # No kernel PSI -> SKIP the start (logged once), don't restart-loop. Without this,
      # StandardError=null swallows the script's FATAL and you'd flap silently every 5s.
      ConditionPathExists = "/proc/pressure/cpu";
      StartLimitIntervalSec = 60;   # backstop for any OTHER rapid failure
      StartLimitBurst = 5;
    };

    serviceConfig = {
      ExecStart  = "${pkgs.babashka}/bin/bb ${../../scripts/syshealth.bb}";   # <- point at wherever the .bb lives
      Restart    = "always";
      RestartSec = "5s";

      # Outrank the pathology on every axis the watcher observes:
      Nice = -10;             # CPU: stay schedulable on a pegged box. Real-elapsed math keeps
      #      accuracy, but a starved sampler still MISSES short episodes.
      OOMScoreAdjust = -500;  # MEM: survive the memory spike you're observing. Negative analog
      #      of Nice — NOT MemoryMax, which would do the OOM-killing for you.
      # IO: intentionally default (best-effort). The watcher does no block IO — it reads /proc
      #     (pseudo-fs) and spawns top — so an io class is moot, and "idle" would repeat the
      #     positive-nice mistake on the io axis.

      StandardOutput = "journal";   # snapshots + recovery summaries
      StandardError  = "null";      # drop the \r-based TTY ticker (journal-hostile)

      NoNewPrivileges = true;
      PrivateTmp = true;            # harmless; script uses no temp files
    };
  };
}

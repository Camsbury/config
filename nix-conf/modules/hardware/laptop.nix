{
  config,
  pkgs,
  sources,
  ...
}:

{
  imports = [
    "${sources.nixos-hardware}/common/pc/laptop"
  ];
  boot.kernelParams = [
    "mem_sleep_default=deep"
  ];
  services = {
    libinput = {
      enable = true;
      touchpad.naturalScrolling = true;
      touchpad.tapping = false;
    };
    upower.enable = true;
  };
  environment.systemPackages = with pkgs; [
    check-low-battery
    xbacklight
  ];

  # Lets scripts/brightness.sh set the panel brightness without a password.
  security.sudo.extraRules = [
    {
      users = [ "ALL" ];
      commands = [
        {
          command = "/usr/bin/env tee /sys/class/backlight/intel_backlight/brightness";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # --- low-battery warning ---
  systemd.user.services.check-low-battery = {
    description = "Notifier";
    path = [ pkgs.libnotify ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.check-low-battery}/bin/check-low-battery";
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

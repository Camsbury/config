{
  config,
  pkgs,
  sources,
  ...
}:

{
  imports = [
    "${sources.nixos-hardware}/common/pc/laptop"
    ./check-battery.nix
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
}

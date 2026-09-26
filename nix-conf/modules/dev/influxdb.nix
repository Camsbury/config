{ config, pkgs, ... }:

# Opt-in: machines import this file directly, and ./default.nix does not.
# The influxdb2 time-series server you develop against. The engine path is
# a mount on one machine, so it is set in that machine's file.
{
  services.influxdb2 = {
    enable = true;
  };
  environment.systemPackages = with pkgs; [
    influxdb2
  ];
}

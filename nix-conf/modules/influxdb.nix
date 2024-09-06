{ config, pkgs, ... }:

{
  services.influxdb2 = {
    enable = true;
  };
  environment.systemPackages = with pkgs; [
    influxdb2
  ];
  environment.variables = {
    INFLUXD_ENGINE_PATH="/media/monoid/influxdbv2/engine";
  };
}

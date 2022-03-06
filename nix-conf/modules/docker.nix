{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
  ];

  users = {
    groups.docker = {};
    users.default.extraGroups = ["docker"];
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
}

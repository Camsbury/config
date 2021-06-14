{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    docker
    docker_compose
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

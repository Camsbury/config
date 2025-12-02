{ config, lib, pkgs, ... }:

{
  systemd.user.services.bb-nrepl = {
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    description = "babashka nrepl: running on 55555";
    environment = {};
    serviceConfig = {
      Type = "simple";
      WorkingDirectory = "/home/camsbury";
      Environment = "PATH=/run/wrappers/bin:/run/current-system/sw/bin";
      ExecStart = "${pkgs.runtimeShell} -c 'source ${config.system.build.setEnvironment}; ${pkgs.babashka}/bin/bb --nrepl-server 55555'";
    };
  };
}

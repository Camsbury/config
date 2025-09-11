{ config, pkgs, ... }:

{
  programs.slock.enable = true;
  programs.xss-lock = {
    enable = true;
    lockerCommand = "${config.security.wrapperDir}/slock";
    extraOptions = [
      "-v"
      "--transfer-sleep-lock"
    ];
  };
}

{ config, pkgs, ... }:

{
  security.wrappers.slock.source = "${pkgs.slock.out}/bin/slock";
  programs.xss-lock = {
    enable = true;
    lockerCommand = "${pkgs.slock}/bin/slock";
  };
}

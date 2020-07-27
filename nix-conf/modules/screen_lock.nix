{ config, pkgs, ... }:

{
  environment.systemPackages = [pkgs.slock];
  security.wrappers.slock.source = "${pkgs.slock.out}/bin/slock";
  programs.xss-lock = {
    enable = true;
    lockerCommand = "slock";
  };
}

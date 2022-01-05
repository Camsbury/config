{ config, pkgs, ... }:

{
  programs.adb.enable = true;
  users = {
    groups.adbusers = {};
    users.default.extraGroups = ["adbusers"];
  };
  environment.systemPackages = with pkgs; [
    android-studio
  ];
  environment.variables = {
    "_JAVA_AWT_WM_NONREPARENTING" = "1";
  };
}

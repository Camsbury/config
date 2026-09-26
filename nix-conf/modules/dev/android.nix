{ config, pkgs, ... }:

# Opt-in: machines import this file directly, and ./default.nix does not.
# The Android SDK and studio, plus the adb device group.
{
  users = {
    groups.adbusers = { };
    users.default.extraGroups = [ "adbusers" ];
  };
  environment.systemPackages = with pkgs; [
    android-studio
  ];
  environment.variables = {
    "_JAVA_AWT_WM_NONREPARENTING" = "1";
  };
}

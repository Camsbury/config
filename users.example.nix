# User configuration for this machine

{ config, pkgs, ... }:

{
  users.mutableUsers = false;
  # replace `userName` in both places with the user name
  users.users.userName = {
    home = "/home/userName"
    extraGroups = ["wheel" "networkmanager" "docker"];
    # the result of running `mkpasswd -m sha-512` with the password
    # make sure you `unset HISTFILE in the session you do this with`
    hashedPassword = "$6$WLAtMNXB.7dV5d.J$Dh26FhEK6GLr3MGmDlv9M9ZBu1TFqsxZWV91GRsoglRsHwhHIX2WK9Dfr.86XjaTxDYmNNoO8nca2YUI5X7T81";
    isNormalUser = true;
    shell = pkgs.zsh;
  };
}

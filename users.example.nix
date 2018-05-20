# User configuration for this machine

{ config, pkgs, ... }:

{
  users.mutableUsers = false;
  users.users.userName = {
    extraGroups = ["wheel" "networkmanager"];
    # the result of running `mkpasswd -m sha-512` with the password
    hashedPassword = "$6$WLAtMNXB.7dV5d.J$Dh26FhEK6GLr3MGmDlv9M9ZBu1TFqsxZWV91GRsoglRsHwhHIX2WK9Dfr.86XjaTxDYmNNoO8nca2YUI5X7T81";
    isNormalUser = true;
    shell = pkgs.zsh;
  };
}

{ config, pkgs, ... }:

# Opt-in: machines import this file directly, and ./default.nix does not.
# Digital painting.
{
  environment.systemPackages = with pkgs; [
    krita
  ];
}

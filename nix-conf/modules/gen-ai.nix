{ config, pkgs, ... }:

let
  peon-flake = builtins.getFlake "github:PeonPing/peon-ping";
  peon-ping = peon-flake.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  environment = {
    systemPackages = with pkgs; [
      lmstudio
      peon-ping
    ];
  };
}

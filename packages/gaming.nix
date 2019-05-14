{ pkgs }:
let
  machine = import ../machine.nix;
in
  (if machine.gaming
  then [pkgs.steam]
  else [])

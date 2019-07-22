{ pkgs }:
let
  machine = import ../machine.nix;
in
  (if machine.gaming
  then with pkgs; [
    nvtop
    steam
  ]
  else [])

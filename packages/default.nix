{ pkgs }:

let
  shared = import ./shared.nix {inherit pkgs;};
  gaming = import ./gaming.nix {inherit pkgs;};
in
  shared ++ gaming

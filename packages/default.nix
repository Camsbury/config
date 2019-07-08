{ pkgs }:

let
  shared = import ./shared.nix {inherit pkgs;};
  linux  = import ./linux.nix  {inherit pkgs;};
  darwin = import ./darwin.nix {inherit pkgs;};
  gaming = import ./gaming.nix {inherit pkgs;};
in
  shared ++ linux ++ darwin ++ gaming

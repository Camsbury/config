let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    rev = "31ffc50c571";
    sha256 = "1gg87k49rmdylmzxjzmllng78qr6wmssnci05z1kij3715wkqc5j";
  })

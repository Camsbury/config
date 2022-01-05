let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    # rev = "31ffc50c571";
    # sha256 = "1gg87k49rmdylmzxjzmllng78qr6wmssnci05z1kij3715wkqc5j";
    rev = "ac169ec6371f0d835542db654a65e0f2feb07838"; # pin
    sha256 = "0bwjyz15sr5f7z0niwls9127hikp2b6fggisysk0cnk3l6fa8abh";
  })

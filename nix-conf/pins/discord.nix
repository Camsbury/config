let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    rev = "51bcdc4cdaa";
    sha256 = "0zpf159nlpla6qgxfgb2m3c2v09fz8jilc21zwymm59qrq6hxscm";
})

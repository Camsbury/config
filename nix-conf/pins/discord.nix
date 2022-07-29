let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    # rev = "51bcdc4cdaa";
    # sha256 = "0zpf159nlpla6qgxfgb2m3c2v09fz8jilc21zwymm59qrq6hxscm";
    rev = "72b1ec0a79b1"; # pin
    sha256 = "05r9dp15q6n6wxp37d81x31j5m5qpwcj23y2pfvaybcrdayg4x8x";
})

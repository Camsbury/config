let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs-channels";
    rev    = "20b993ef2c9e818a636582ade9597f71a485209d";
    sha256 = "0plb93vw662lwxpfac7karsqkkajwr6xp5pfgij2l67bn1if3xd6";
  })
  # fetchFromGitHub {
  #   owner = "NixOS";
  #   repo  = "nixpkgs-channels";
  #   rev    = "nixos-unstable";
  #   sha256 = "?";
  # }

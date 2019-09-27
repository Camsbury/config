let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs-channels";
    # rev    = "20b993ef2c9e818a636582ade9597f71a485209d";
    # sha256 = "0plb93vw662lwxpfac7karsqkkajwr6xp5pfgij2l67bn1if3xd6";
    # rev    = "aa2a7e49b82567bad8934cc983f06dd5abc68f49";
    # sha256 = "11vjafapanzq26cq84qx1h1h6324xl6r9p5q3qqvdi11cy6d4li5";
    rev    = "2436c27541b2f52deea3a4c1691216a02152e729";
    sha256 = "0p98dwy3rbvdp6np596sfqnwlra11pif3rbdh02pwdyjmdvkmbvd";
  })
  # fetchFromGitHub {
  #   owner = "NixOS";
  #   repo  = "nixpkgs-channels";
  #   rev    = "nixos-unstable";
  #   sha256 = "?";
  # }

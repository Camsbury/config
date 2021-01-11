let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    # rev = "0da76dab4c2acce5ebf404c400d38ad95c52b152";
    # sha256 = "1lj3h4hg3cnxl3avbg9089wd8c82i6sxhdyxfy99l950i78j0gfg";
    # rev = "5101b357ec30c1ac4a9273b379e631f841af9fa3";
    # sha256 = "0lm88b7k1bx2sj28plw1djs5s5bgf8qdrzr683mf21kww4y03i5m";
    rev = "479867700baa7ced259c979a0f724915c4d46d12";
    sha256 = "0dwci1sw81qn0b0cnksw3qf9lfhyz0rfvs14l3yh9iq6qfcs2aq7";
  })

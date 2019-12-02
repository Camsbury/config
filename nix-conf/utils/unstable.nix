let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs-channels";
    # rev    = "2436c27541b2f52deea3a4c1691216a02152e729";
    # sha256 = "0p98dwy3rbvdp6np596sfqnwlra11pif3rbdh02pwdyjmdvkmbvd";
    rev    = "f97746ba2726128dcf40134837ffd13b4042e95d";
    sha256 = "1ramsxyv4ajkc2jmk4cv8jnzlrbqq1hswigw9dv29hz60scfzv4m";
  })
  # fetchFromGitHub {
  #   owner = "NixOS";
  #   repo  = "nixpkgs-channels";
  #   rev    = "nixos-unstable";
  #   sha256 = "?";
  # }

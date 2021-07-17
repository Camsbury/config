let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    # owner = "NixOS";
    # my fork
    owner = "Camsbury";
    repo  = "nixpkgs";
    # rev = "e1f8852faac"; # pin
    # sha256 = "16zxn0lnj10wcdarsyazc2137lqgxb0fi80yny91mzbzisb2w7gs";
    rev = "90b3800db9f633aaf25e09902a5866f7355f2548";
    sha256 = "1vrhwlwc7x3f0xn6cgckrfp8vky0yws30d52hq3miy122d03gcc0";
  })

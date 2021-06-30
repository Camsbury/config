let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    rev = "e1f8852faac"; # pin
    sha256 = "16zxn0lnj10wcdarsyazc2137lqgxb0fi80yny91mzbzisb2w7gs";
  })

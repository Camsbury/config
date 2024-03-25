let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    # this one probably works for WC3
    # rev = "e1f8852faac"; # pin
    # sha256 = "16zxn0lnj10wcdarsyazc2137lqgxb0fi80yny91mzbzisb2w7gs";
    # rev = "710fed5a248";
    # hash = "sha256-kCmnDeiaMsdhfnNKjxdOzwRh2H6eQb8yWAL+nNabC/Y=";
    rev = "b50a77c03d64";
    hash = "sha256-zJaF0RkdIPbh8LTmnpW/E7tZYpqIE+MePzlWwUNob4c=";
  })

let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    rev = "b50a77c03d64";
    hash = "sha256-zJaF0RkdIPbh8LTmnpW/E7tZYpqIE+MePzlWwUNob4c=";
})

let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    rev = "d6b3ddd253c5";
    hash = "sha256-kR7C7Fqt3JP40h0mzmSZeWI5pk1iwqj4CSeGjnUbVHc=";
})

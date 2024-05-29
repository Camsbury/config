let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    # rev = "d6b3ddd253c5";
    # hash = "sha256-kR7C7Fqt3JP40h0mzmSZeWI5pk1iwqj4CSeGjnUbVHc=";
    rev = "e2dd4e18cc1c";
    hash = "sha256-usk0vE7VlxPX8jOavrtpOqphdfqEQpf9lgedlY/r66c=";
})

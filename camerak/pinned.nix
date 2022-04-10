let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
import (fetchFromGitHub {
  owner = "NixOS";
  repo  = "nixpkgs";
  rev = "710fed5a248";
  hash = "sha256-kCmnDeiaMsdhfnNKjxdOzwRh2H6eQb8yWAL+nNabC/Y=";
})

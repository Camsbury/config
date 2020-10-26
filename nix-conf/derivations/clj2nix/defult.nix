{ pkgs ? (import <nixpkgs> {}) }:

pkgs.callPackage (pkgs.fetchFromGitHub {
  owner = "hlolli";
  repo = "clj2nix";
  rev = "bc74da7531814cf894be5b618d40de8298547da9";
  sha256 = "0z5f5vs2ibhni7ydic3l5f8wy53wbwxf7pax963pcj714m3mlp47";
}) {}

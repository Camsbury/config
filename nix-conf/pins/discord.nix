let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
  discord = (import ../pins.nix).discord;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    rev = discord.rev;
    hash = discord.hash;
})

let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
import (fetchFromGitHub {
  owner = "NixOS";
  repo  = "nixpkgs";
  rev = "1c2986bbb806c57f9470bf3231d8da7250ab9091"; # pin
  sha256 = "0y1275nzlmsys5rk7ivzbdc8cpjs9cbk0wz6yh3i2c57b8nbd3ym";
})

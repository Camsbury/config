let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    # rev = "4cb48cc25622334f17ec6b9bf56e83de0d521fb7";
    # sha256 = "0z005p4jwlnfh9gbgjc3anzrabzdys2d94l4chvdhzxr1pyj4imy";
    rev = "1c2986bbb806c57f9470bf3231d8da7250ab9091";
    sha256 = "0y1275nzlmsys5rk7ivzbdc8cpjs9cbk0wz6yh3i2c57b8nbd3ym";
  })

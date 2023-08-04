let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    # current nixos channel set at:
    # https://github.com/NixOS/nixpkgs/archive/4d2b37a8.tar.gz
    # rev = "03fb7220163";
    # hash = "sha256-Y/uC2ZmkQkyrdRZ5szZilhZ/46786Wio5CGTgL+Vb/c=";
    # rev = "fe2ecaf706a";
    # hash = "sha256-JEdQHsYuCfRL2PICHlOiH/2ue3DwoxUX7DJ6zZxZXFk=";
	  rev = "7cc30fd5372d";
    hash = "sha256-gBlBtk+KrezFkfMrZw6uwTuA7YWtbFciiS14mEoTCo0=";
})

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
	  # rev = "7cc30fd5372d";
    # hash = "sha256-gBlBtk+KrezFkfMrZw6uwTuA7YWtbFciiS14mEoTCo0=";
    # rev = "844ffa82bbe2";
    # hash = "sha256-D21ctOBjr2Y3vOFRXKRoFr6uNBvE8q5jC4RrMxRZXTM=";
    # rev = "fdd898f8f79e";
    # hash = "sha256-mnQjUcYgp9Guu3RNVAB2Srr1TqKcPpRXmJf4LJk6KRY=";
    # rev = "5a09cb4b393d";
    # hash = "sha256-RyJTnTNKhO0yqRpDISk03I/4A67/dp96YRxc86YOPgU=";
    rev = "eabe8d3eface";
    hash = "sha256-OTeQA+F8d/Evad33JMfuXC89VMetQbsU4qcaePchGr4=";
})

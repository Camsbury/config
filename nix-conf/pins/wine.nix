let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    rev = "e1f8852faac"; # pin
    sha256 = "16zxn0lnj10wcdarsyazc2137lqgxb0fi80yny91mzbzisb2w7gs";
    # rev = "639d0ff3523f";
    # sha256 = "1a70hh19v3x64yry97akkdmdjb6xf7h255vl4vzdm6ifaz4arb1g";
  })

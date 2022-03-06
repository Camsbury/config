let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
import (fetchFromGitHub {
  owner = "NixOS";
  repo  = "nixpkgs";
  # rev = "ac169ec6371f0d835542db654a65e0f2feb07838"; # pin
  # sha256 = "0bwjyz15sr5f7z0niwls9127hikp2b6fggisysk0cnk3l6fa8abh";
  # rev = "7f9b6e2babf"; # pin
  # sha256 = "03nb8sbzgc3c0qdr1jbsn852zi3qp74z4qcy7vrabvvly8rbixp2";
  # rev = "639d0ff3523f";
  # sha256 = "1a70hh19v3x64yry97akkdmdjb6xf7h255vl4vzdm6ifaz4arb1g";
  rev = "3e072546ea9";
  sha256 = "1b51j0zz4gfcmq1lzh0f9yj6h904p7fgskshvc70dkjkdg9k2x7j";
})

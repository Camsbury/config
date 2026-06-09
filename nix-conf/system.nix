let
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/bd0ff2d3eac2.tar.gz";
    sha256 = "0i4ymrwz6aanx3byjnignx13sdrdp1v1llgg81jn3mjz5q89ik5b";
  };
in
import "${nixpkgs}/nixos" {
configuration = /etc/nixos/configuration.nix;
}

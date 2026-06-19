let
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/bd0ff2d3eac2.tar.gz";
    sha256 = "0i4ymrwz6aanx3byjnignx13sdrdp1v1llgg81jn3mjz5q89ik5b";
  };
  home-manager-pkgs = builtins.fetchTarball {
    url = "https://github.com/rycee/home-manager/archive/release-26.05.tar.gz";
    sha256 = "10y7xwm4ykcs3pqyj80ri8vwgwwvzzax32f2vgpqb8qc25xv2sv4";
  };
in
import "${nixpkgs}/nixos" {
configuration = /etc/nixos/configuration.nix;
specialArgs = { inherit home-manager-pkgs; };
}

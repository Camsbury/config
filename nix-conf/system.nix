let
  sources = import ./npins;
in
import "${sources.nixpkgs}/nixos" {
  configuration = /etc/nixos/configuration.nix;
  specialArgs = { inherit sources; };
}

let
  pkgs = import <nixpkgs> {};
  duka = pkgs.callPackage (import ./default.nix) {inherit pkgs;};
in
with pkgs;
mkShell rec {
  name = "dukaShell";
  buildInputs = [
    duka
  ];
}

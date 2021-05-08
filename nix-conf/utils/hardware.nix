let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixos-hardware";
    rev    = "f7540d6c27704ec0fe56ecc8b2a9b663181850b0";
    sha256 = "1rr470h5frly4a6wwpm1pmfgv57v5f7zwlc73sdx93ms7pc050lf";
  }

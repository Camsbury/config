let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixos-hardware";
    # rev    = "03db9669a6fc712e9537201d55639287eb606765";
    # sha256 = "1g8kap5qzva58pcwn2xj1cs0k9w9mpbrlk5diaaarlgizp4l2x0z";
    # rev    = "f4364f2457051b407899f7fc3bced4ac952644ff";
    # sha256 = "1g8kap5qzva58pcwn2xj1cs0k9w9mpbrlk5diaaarlgizp4l2x0z";
    rev    = "16336614d3fb785e9526d19e461dc57ef081e8c4";
    sha256 = "1y9xsh5dmdb8jliikz2ps5j11i7jbwlygkmbz6asw31g2ghqrm0w";
  }

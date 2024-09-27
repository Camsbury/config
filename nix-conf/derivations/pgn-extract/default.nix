{stdenv, fetchurl}:

stdenv.mkDerivation (rec {
  version = "24-11";
  pname = "pgn-extract";
  name = "${pname}-${version}";
  src = fetchurl {
    url = "https://www.cs.kent.ac.uk/~djb/${pname}/${pname}-${version}.tgz";
    hash = "sha256-6aMqypVmb8qG5WOi30hDv2wPZQjXd6rS10OK1riMf/U=";
  };
  installPhase =
    ''
    mkdir -p $out/bin
    cp ${pname} $out/bin/${pname}
    chmod +x $out/bin/${pname}
    '';
  phases = [
    "unpackPhase"
    "buildPhase"
    "installPhase"
  ];
})

{stdenv, fetchurl}:

stdenv.mkDerivation (rec {
  version = "21-02";
  pname = "pgn-extract";
  name = "${pname}-${version}";
  src = fetchurl {
    url = "https://www.cs.kent.ac.uk/~djb/${pname}/${pname}-${version}.tgz";
    sha256 = "0fslk6mnmk8asp746zzy7xd44pzqgdvslp01zcfv58j2j004469i";
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

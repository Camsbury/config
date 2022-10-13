{stdenv, fetchurl}:

stdenv.mkDerivation (rec {
  version = "22-11";
  pname = "pgn-extract";
  name = "${pname}-${version}";
  src = fetchurl {
    url = "https://www.cs.kent.ac.uk/~djb/${pname}/${pname}-${version}.tgz";
    hash = "sha256-Mx6E1VKZmH3CfxWSkuo7WblMR+3JcvMulvTmwMhiHAs=";
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

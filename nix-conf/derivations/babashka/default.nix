{stdenv, fetchurl, pkgs}:

stdenv.mkDerivation (rec {
  version = "0.1.3";
  pname = "babashka";
  name = "${pname}-${version}";
  src = fetchurl {
    url = "https://github.com/borkdude/babashka/releases/download/v0.1.3/${pname}-${version}-linux-static-amd64.zip";
    sha256 = "14dnb6yh9dwqn0dqvwm7qldwy05znd3s674j7hi7qffnxcl40m03";
  };
  nativeBuildInputs = [ pkgs.unzip ];
  unpackPhase = ''
    unzip ${src}
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp bb $out/bin/bb
  '';
  phases = [
    "unpackPhase"
    "installPhase"
  ];
})

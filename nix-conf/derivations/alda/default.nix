{stdenv, fetchurl}:

stdenv.mkDerivation (rec {
  version = "1.3.3";
  pname = "alda";
  name = "${pname}-${version}";
  src = fetchurl {
    url = https://github.com/alda-lang/alda/releases/download + "/${version}/alda";
    sha256 = "1jv3ji96h3wral7rvimc39sfr9f9vnkmmh51babc2cjc786ibdl7";
  };
  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/alda
    chmod +x $out/bin/alda
  '';
  phases = [
    "installPhase"
  ];
})

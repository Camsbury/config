{stdenv, fetchurl}:

stdenv.mkDerivation (rec {
  version = "2.2.7";
  pname = "alda";
  name = "${pname}-${version}";
  src = fetchurl {
    url = https://alda-releases.nyc3.digitaloceanspaces.com + "/${version}/client/linux-amd64/alda";
    # url = https://github.com/alda-lang/alda/releases/download + "/${version}/alda";
    hash = "sha256-goltPN54zcz3KgCky1Wum0CkV1knkx0L0MgX3X3lTx4=";
    # sha256 = "1jv3ji93h3wral7rvimc39sfr9f9vnkmmh51babc2cjc786ibdl7";
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

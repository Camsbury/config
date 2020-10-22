{stdenv, fetchurl, pkgs}:

stdenv.mkDerivation (rec {
  version = "0.10.82";
  pname = "datomic-cli";
  name = "${pname}-${version}";
  src = fetchurl {
    url = "https://datomic-releases-1fc2183a.s3.amazonaws.com/tools/datomic-cli/datomic-cli-0.10.82.zip";
    sha256 = "0h0482lb3jyaggra36rn3vmgch0wlfxar00dpmsss47l12w5q7lx";
  };
  nativeBuildInputs = [ pkgs.unzip ];
  unpackPhase = ''
    unzip ${src}
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp datomic-cli/* $out/bin/
    export ESCAPED_PATH=$(echo ${pkgs.bash} | sed -e 's/[\/&]/\\&/g')
    sed -i "s/\/bin\/bash/$ESCAPED_PATH\/bin\/bash/g" $out/bin/*
    chmod +x $out/bin/*
  '';
  phases = [
    "unpackPhase"
    "installPhase"
  ];
  propagatedBuildInputs = [ pkgs.bash ];
})

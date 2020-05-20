{stdenv, fetchurl, pkgs}:


stdenv.mkDerivation (rec {
  version = "1.0.0";
  pname = "datomic-socks-proxy";
  name = "${pname}-${version}";
  src = fetchurl {
    url = "https://docs.datomic.com/cloud/files/datomic-socks-proxy";
    sha256 = "0s7qw88gni2j1hj058ya1nc4mn0xppqphsgi58p30hl0f683yqwp";
  };
  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/datomic-socks-proxy
    export ESCAPED_PATH=$(echo ${pkgs.bash} | sed -e 's/[\/&]/\\&/g')
    sed -i "s/\/bin\/bash/$ESCAPED_PATH\/bin\/bash/g" $out/bin/datomic-socks-proxy
    chmod +x $out/bin/datomic-socks-proxy
  '';
  phases = [
    "installPhase"
  ];
  propagatedBuildInputs = [ pkgs.bash ];
})

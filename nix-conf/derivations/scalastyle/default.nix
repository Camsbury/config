{stdenv, fetchurl, pkgs}:

stdenv.mkDerivation (rec {
  version = "2.12";
  pname = "scalastyle";
  name = "${pname}-${version}";
  config = fetchurl {
    url = http://www.scalastyle.org/scalastyle_config.xml;
    sha256 = "1rd2jyy4y01girbqisjzw7w79ckzl9z6mgql4gc15ry3vmmryyz3";
  };
  jar = fetchurl {
    url = https://repo1.maven.org/maven2/org/scalastyle/ + "${pname}_${version}/1.0.0/${pname}_${version}-1.0.0-batch.jar" ;
    sha256 = "1jzdb9hmvmhz3niivm51car74l8f3naspz4b3s6g400dpsbzvnp9";
  };
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib
    ls
    cp ${jar} $out/lib/${name}.jar
    cp ${config} $out/lib/config.xml
    echo "#!/usr/bin/env sh" > $out/bin/${pname}
    echo java -jar $out/lib/${name}.jar --config $out/lib/config.xml "$@" >> $out/bin/${pname}
    chmod +x $out/bin/${pname}
  '';
  phases = [
    "installPhase"
  ];
})


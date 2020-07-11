{stdenv, fetchurl, pkgs}:


stdenv.mkDerivation (rec {
  version = "1.0.0";
  pname = "check-low-battery";
  name = "${pname}-${version}";
  src = ./run.sh;
  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/check-low-battery
    export ESCAPED_PATH=$(echo ${pkgs.upower} | sed -e 's/[\/&]/\\&/g')
    sed -i "s/upower/$ESCAPED_PATH\/bin\/upower/g" $out/bin/check-low-battery
    chmod +x $out/bin/check-low-battery
  '';
  dontUnpack = true;
  propagatedBuildInputs = [
    pkgs.libnotify
  ];
})

{stdenv, fetchurl, pkgs}:

stdenv.mkDerivation (rec {
  version = "20.05.09";
  pname = "clj-kondo";
  name = "${pname}-${version}";
  # buildInputs = [
  #   pkgs.unzip
  # ];
  src = fetchurl {
    url = https://github.com/borkdude/clj-kondo/releases/download/v2020.05.09/clj-kondo-2020.05.09-linux-static-amd64.zip;
    sha256 = "098c55v014plzk6v5ac22z2myllpip6irby0r2lsyz4yyjhb79jz";
  };
  nativeBuildInputs = [ pkgs.unzip ];
  buildInputs = [ pkgs.unzip ];
  unpackPhase = ''
    unzip ${src}
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp clj-kondo $out/bin/clj-kondo
    chmod +x $out/bin/clj-kondo
  '';
  phases = [
    "unpackPhase"
    "installPhase"
  ];
})

{stdenv, fetchurl, pkgs}:

stdenv.mkDerivation (rec {
  version = "45e4e97ba4ec30c7e23296a75427964fc27fb029";
  pname = "alias-tips";
  name = "${pname}-${version}";
  src = fetchurl {
    url = https://github.com/djui/alias-tips/archive/45e4e97.zip;
    sha256 = "1w7br909l9rmpywphqp4qh57gczwrgc2zrfnx24xzpadv1dgimv9";
  };
  nativeBuildInputs = [ pkgs.unzip ];
  buildInputs = [ pkgs.unzip ];
  unpackPhase = ''
    unzip ${src}
  '';
  installPhase = ''
    mkdir -p $out/share/zsh/plugins/
    cp -r ${pname}-${version} $out/share/zsh/plugins/alias-tips
    export ESCAPED_PATH=$(echo ${pkgs.python3} | sed -e 's/[\/&]/\\&/g')
    sed -i "s/^\(\s*\)python/\1$ESCAPED_PATH\/bin\/python/g" $out/share/zsh/plugins/alias-tips/alias-tips.plugin.zsh
  '';
  phases = [
    "unpackPhase"
    "installPhase"
  ];
})

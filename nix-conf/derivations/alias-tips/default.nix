{stdenv, fetchurl, pkgs}:

stdenv.mkDerivation (rec {
  version = "master";
  pname = "alias-tips";
  name = "${pname}-${version}";
  src = fetchurl {
    url = https://github.com/djui/alias-tips/archive/master.zip;
    sha256 = "03rn2723mp5d851bgdbxp4na10fwcbb40h5630h5z6dg0kz84db0";
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

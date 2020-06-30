{stdenv, fetchurl, pkgs}:

stdenv.mkDerivation (rec {
  version = "master";
  pname = "alias-tips";
  name = "${pname}-${version}";
  src = fetchurl {
    url = https://github.com/djui/alias-tips/archive/master.zip;
    sha256 = "02z70g083izrh1zcfp58m7ggz16cqaag06cs0q6hyalbldbhxnfs";
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

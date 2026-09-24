{stdenv, fetchurl, pkgs}:

stdenv.mkDerivation (rec {
  version = "41cb143ccc3b8cc444bf20257276cb43275f65c4";
  pname = "alias-tips";
  name = "${pname}-${version}";
  src = fetchurl {
    url = https://github.com/djui/alias-tips/archive/41cb143.zip;
    hash = "sha256-gvq+PA031bPGGL6Yt0xDgBlZVm5WARwWFmCQM6dVWlg=";
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

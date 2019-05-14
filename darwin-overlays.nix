
[(self: super: {
  enchant =
    super.stdenv.mkDerivation rec {
      pname = "enchant";
      version = "1.6.0";
      name = "${pname}-${version}";
      src = super.fetchurl {
        url = "http://www.abisource.com/downloads/${pname}/${version}/${name}.tar.gz";
        sha256 = "0zq9yw1xzk8k9s6x83n1f9srzcwdavzazn3haln4nhp9wxxrxb1g";
      };

      nativeBuildInputs = with self; [ pkgconfig ];
      buildInputs = with self; [ aspell glib hunspell hspell ];

      meta = with super.stdenv.lib; {
        description = "Generic spell checking library";
        homepage = http://www.abisource.com/enchant;
        platforms = platforms.unix;
        license = licenses.lgpl21;
      };
    };
    python36 = super.python36.override {
      packageOverrides = (
        pythonSelf: pythonSuper:
          let
            buildPythonPackage = pythonSuper.buildPythonPackage;
            fetchPypi = pythonSuper.fetchPypi;
          in
            {
              pylint = pythonSuper.pylint.overridePythonAttrs (
                oldAttrs: { doCheck = false; }
              );
            });};
  xndr = super.callPackage (builtins.fetchTarball
    "https://github.com/Camsbury/xndr/archive/094be18.tar.gz") {pkgs = self;};
})]

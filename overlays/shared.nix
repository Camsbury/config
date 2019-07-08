[(self: super: {
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
          }
    );
  };

  rural = super.rustPlatform.buildRustPackage rec {
    pname = "rural";
    version = "0.8.1";
    src = super.fetchFromGitHub {
      owner  = "saghm";
      repo   = pname;
      rev    = "be6f7ac7b4ea926d0c6085819d9b4189206914d9";
      sha256 = "1z87dlkvla1alf2whjllf999kl3z18kjjsl7pa5y68amwhd9f2sj";
    };
    cargoSha256 = "1z4r50qvqzywdcn2wybrajdz7bdhwrbzpm072brhqm4vfxyf23rk";

    propagatedBuildInputs = [
      self.pkg-config
      self.openssl
    ];

    buildInputs = super.stdenv.lib.optionals super.stdenv.isDarwin [ self.darwin.Security self.darwin.apple_sdk.frameworks.CoreServices ];

    doCheck = false;

    meta = with super.stdenv.lib; {
      homepage    = https://github.com/saghm/rural;
      license     = with licenses; [ mit ];
      platforms   = platforms.all;
    };
  };

  xndr = super.callPackage (builtins.fetchTarball
    "https://github.com/Camsbury/xndr/archive/094be18.tar.gz") {pkgs = self;};
})]

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
  xndr = super.callPackage (builtins.fetchTarball
    "https://github.com/Camsbury/xndr/archive/094be18.tar.gz") {pkgs = self;};
})]

let
  pythonOverride = {
    packageOverrides = pythonSelf: pythonSuper: {
      yapf = pythonSuper.yapf.overridePythonAttrs (
        oldAttrs: {
          version = "0.24.0";
          src = pythonSuper.fetchPypi {
            pname = "yapf";
            version = "0.24.0";
            sha256 = "0anwby0ydmyzcsgjc5dn1ryddwvii4dq61vck447q0n96npnzfyf";
          };
        }
      );
    };
  };
  overlays = [
    (self: super: {
      python36 = super.python36.override pythonOverride;
    })
  ];
  pkgs = import <nixpkgs> {inherit overlays;};
in
  with pkgs;
  let
    myPython =
      python36.withPackages (
        pythonPackages: with pythonPackages;
          [ yapf
          ]
      );
  in
    mkShell {
      name = "yapfer";
      buildInputs = [
        myPython
      ];
    }

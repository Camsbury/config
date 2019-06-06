let
  pkgs = import <nixpkgs> {};
in
  with pkgs;
  let
    myPython =
      python3.withPackages (
        pythonPackages: with pythonPackages;
          [ ipython
            pandas
          ]
      );
  in
    mkShell {
      name = "dataAnalysis";
      buildInputs = [
        myPython
      ];
      shellHook = ''
        ipython
      '';
    }

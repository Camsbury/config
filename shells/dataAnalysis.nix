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
            jupyter
            jupyter_core
            jupyter_client
          ]
      );
  in
    mkShell {
      name = "dataAnalysis";
      buildInputs = [
        myPython
      ];
      shellHook = ''
        emacs
      '';
    }

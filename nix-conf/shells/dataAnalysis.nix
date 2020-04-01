let
  pkgs = import <nixpkgs> {};
in
  with pkgs;
  let
    myPython =
      python3.withPackages (
        pythonPackages: with pythonPackages;
          [ isort
            ipython
            mypy
            pandas
            pyflakes
            pylint
            jedi
            jupyter
            jupyter_core
            jupyter_client
            yapf
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

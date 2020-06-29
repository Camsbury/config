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
            pyflakes
            pylint
            jedi
            yapf
            numpy
          ]
      );
  in
    mkShell {
      name = "python-shell";
      buildInputs = [
        myPython
      ];
    }

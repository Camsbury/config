let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
  pkgs = (import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    # rev    = "20b993ef2c9e818a636582ade9597f71a485209d";
    # sha256 = "0plb93vw662lwxpfac7karsqkkajwr6xp5pfgij2l67bn1if3xd6";
    rev    = "9b13731b72d643a4d8297488823c0ed115bf3c4f";
    sha256 = "0s9mjdbawbmqgjv88sa06hhm78za5j8qfdz45kyi1ak925w6g0yp";
    })) {};
in
  with pkgs;
  let
    myPython =
      python3.withPackages (
        pythonPackages: with pythonPackages;
          [ ipython
            jupyter
            jupyter_core
            jupyter_client
            sqlalchemy
            psycopg2
            alembic
          ]
      );
  in
    mkShell {
      name = "sqlalchemy";
      buildInputs = [
        myPython
      ];
      shellHook = ''
        emacs
      '';
    }

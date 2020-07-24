let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
  nixpkgs = import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs-channels";
    rev    = "aa2a7e49b82567bad8934cc983f06dd5abc68f49";
    sha256 = "11vjafapanzq26cq84qx1h1h6324xl6r9p5q3qqvdi11cy6d4li5";
  });
in
  with (nixpkgs {});

  let
    inherit (lib) optional optionals;
    elixir = beam.packages.erlangR22.elixir_1_9;
  in

    mkShell {
      buildInputs = [ elixir git ]
        ++ optional stdenv.isLinux libnotify # For ExUnit Notifier on Linux.
        ++ optional stdenv.isLinux inotify-tools # For file_system on Linux.
    }

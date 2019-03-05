{ pkgs }:
let
  xndr = pkgs.callPackage (builtins.fetchTarball
    "https://github.com/Camsbury/xndr/archive/094be18.tar.gz") {};
in
  [ xndr
  ]

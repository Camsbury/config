{ pkgs }:
let
  xndr = pkgs.callPackage (builtins.fetchTarball
    "https://github.com/Camsbury/xndr/archive/25fcccb.tar.gz") {};
in
  [ xndr
  ]

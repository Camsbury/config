{ pkgs }:

( with pkgs; if pkgs.stdenv.hostPlatform.system == "x86_64-darwin" then [
    leiningen
  ] else [])

let
  pkgs = import <nixpkgs> {};
  kondoDer = import ../derivations/clj-kondo;
  clj-kondo = with builtins; with pkgs; callPackage kondoDer {
    inherit stdenv;
    inherit fetchurl;
    inherit pkgs;
  };
in
  with pkgs;
  mkShell {
    name = "clojureShell";
    buildInputs = [
      leiningen
      openjdk
      clojure
      clj-kondo
    ];
  }

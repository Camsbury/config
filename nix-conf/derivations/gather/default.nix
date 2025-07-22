{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname   = "gather";
  version = "1.0.0";

  src = pkgs.lib.cleanSource ./.;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/share/${pname}
    cp -r $src/* $out/share/${pname}/

    mkdir -p $out/bin
    makeWrapper ${pkgs.electron}/bin/electron $out/bin/${pname} \
      --add-flags $out/share/${pname}
  '';

  meta = with pkgs.lib; {
    description = "Electron wrapper for the Gather demo app";
    license     = licenses.mit;
    platforms   = platforms.linux ++ platforms.darwin;
  };
}

{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    buildInputs = with pkgs; with pkgs.rPackages; [
      R
      Lahman
      gapminder
      googledrive
      httr
      nycflights13
      rlist
      tidyverse
    ];
}

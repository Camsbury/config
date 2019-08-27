{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    buildInputs = with pkgs; with pkgs.rPackages; [
      R
      Lahman
      anytime
      gapminder
      googledrive
      httr
      maps
      mapproj
      nycflights13
      rlist
      tidyverse
    ];
}

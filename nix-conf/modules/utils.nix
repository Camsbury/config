{ config, pkgs, ... }:

{
  imports = [
  ];
  environment.systemPackages = with pkgs; [
    cachix
    calibre # ebook stuff
    ghostscript # for viewing pdfs
    gnuplot
    mpg123 # used in emacs and other quick mp3 playing
    tetex # latex!
  ];
}

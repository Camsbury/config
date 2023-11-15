{ config, pkgs, ... }:

{
  imports = [
  ];
  environment.systemPackages = with pkgs; [
    cachix
    calibre # ebook stuff
    ghostscript # for viewing pdfs
    gnuplot
    ispell # used for spell check
    mpg123 # used in emacs and other quick mp3 playing
    tetex # latex!
  ];
}

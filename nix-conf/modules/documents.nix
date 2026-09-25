{ pkgs, ... }:

# Reading and writing documents: viewers, typesetting, and the tools that
# writing uses (plotting, spell checking).
{
  environment.systemPackages = with pkgs; [
    calibre # ebook stuff
    ghostscript # for viewing pdfs
    gnuplot
    ispell # used for spell check
    texliveFull # latex!
    zathura
  ];
}

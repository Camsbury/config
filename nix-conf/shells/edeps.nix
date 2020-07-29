let
  pkgs = import <nixpkgs> {};
in
  with pkgs;
  mkShell {
    shellHook = ''
      export LOADPATH="${pkgs.emacs}/share/emacs/site-lisp"
    '';
  }

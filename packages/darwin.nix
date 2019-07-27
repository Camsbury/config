{ pkgs }:

( with pkgs; if pkgs.stdenv.hostPlatform.system == "x86_64-darwin" then [
    (python36.withPackages (
      pythonPackages: with pythonPackages;
        [ isort
          jedi
          mypy
          pyflakes
          pylint
          yapf
        ]
    ))
    (import ../emacs.nix { inherit pkgs; })
  ] else [])

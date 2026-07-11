self: super:

let
  basePkgs = import (import ../pins.nix).unstable {
    config = {
      allowUnfree = true;
    };
  };
  # Would be sweet to use the ones from nixpkgs instead
  compileEmacsFiles = basePkgs.callPackage ./emacsBuilder.nix;
  emacsOverrides = eSelf: eSuper: {
    melpaPackages = eSuper.melpaPackages // {
      eca =
        let
          version = "20260711.1907";
          rev = "b1785deb294796792211207fbc628859f28b6410";
          hash = "sha256-Z98XHBIZUBSYkppl/160kblW3dDEgyPqjvDj+I5+MKk=";
        in
        eSelf.melpaBuild {
          pname = "eca";
          version = version;

          recipe = builtins.toFile "recipe.el" ''
            (eca :fetcher github :repo "editor-code-assistant/eca-emacs")
          '';

          buildInputs = with eSelf.melpaPackages; [
            dash
            f
            markdown-mode
          ];

          src = super.fetchFromGitHub {
            owner = "editor-code-assistant";
            repo = "eca-emacs";
            rev = rev;
            hash = hash;
          };
        };
    };

    magit-difftastic = compileEmacsFiles {
      name = "magit-difftastic.el";
      src = builtins.fetchurl {
        url = "https://raw.githubusercontent.com/rschmukler/magit-difftastic/1e2a1f60288341893a9d21d8a900739be9f34e40/magit-difftastic.el";
        sha256 = "0zr0n9x2029f4f2x33kjs7r826zc1kz7iziq4ik58w1nj4247qxz";
      };
      buildInputs = with eSelf.melpaPackages; [
        cond-let
        difftastic
        llama
        magit
        magit-section
        transient
        with-editor
      ];
    };

    etymology-of-word = compileEmacsFiles {
      name = "etymology-of-word.el";
      src = builtins.fetchurl {
        url = "https://raw.githubusercontent.com/Camsbury/etymology-of-word/master/etymology-of-word.el";
        sha256 = "09yk4qrk3k5ygdqlj3ksdqzxh5532ychs4msphqrw3nim5dxhklw";
      };
      buildInputs = with eSelf.melpaPackages; [
        dash
      ];
    };

    explain-pause-mode = eSelf.melpaBuild {
      pname = "explain-pause-mode";
      version = "0.1";

      recipe = builtins.toFile "recipe.el" ''
        (explain-pause-mode :fetcher github
                            :repo "lastquestion/explain-pause-mode")
      '';

      src = super.fetchFromGitHub {
        owner = "lastquestion";
        repo = "explain-pause-mode";
        rev = "35f7d780a9c164b5c502023746473b1de3857904";
        sha256 = "0d9lwzqqwmz0n94i7959rj7m24265yf3825a5g8cd7fyzxznl1pc";
      };
    };

    hide-comnt = compileEmacsFiles {
      name = "hide-comnt.el";
      src = builtins.fetchurl {
        url = "https://raw.githubusercontent.com/emacsmirror/emacswiki.org/601b51e25e758083e66fab433cf61d22713fed51/hide-comnt.el";
        sha256 = "0v3wgl9r9w0qbvs1cxgl7am9hvpy6hyhvfbsjqix5n0zmdg68s4n";
      };
    };
  };

in
{
  emacsPackages = basePkgs.emacsPackages.overrideScope emacsOverrides;
}

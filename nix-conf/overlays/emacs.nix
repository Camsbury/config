super: eSelf: eSuper:
let
  compileEmacsFiles =  super.callPackage ./emacsBuilder.nix;
in
{
  melpaPackages = eSuper.melpaPackages // {
    eca =
      let
        version = "20260924.1516";
        rev = "4647946db593a0a1e45f77b1a996d4843f6e24a9";
        hash = "sha256-2EL1fTQthbahEiqht/QsR7GbRg2X/swPIT6dXWgG5+M=";
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

  hide-comnt = compileEmacsFiles {
    name = "hide-comnt.el";
    src = builtins.fetchurl {
      url = "https://raw.githubusercontent.com/emacsmirror/emacswiki.org/601b51e25e758083e66fab433cf61d22713fed51/hide-comnt.el";
      sha256 = "0v3wgl9r9w0qbvs1cxgl7am9hvpy6hyhvfbsjqix5n0zmdg68s4n";
    };
  };
}

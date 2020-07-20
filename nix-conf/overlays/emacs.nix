self: super:

let
  basePkgs = (
    import ../utils/unstable.nix { config = {allowUnfree = true;}; }
  );
  # Would be sweet to use the ones from nixpkgs instead
  compileEmacsFiles = basePkgs.callPackage ./emacsBuilder.nix;
  emacsOverrides = eSelf: eSuper:
    {
      astyle = compileEmacsFiles {
        name = "astyle.el";
        src = builtins.fetchurl {
          url = https://raw.githubusercontent.com/storvik/emacs-astyle/04ff2941f08c4b731fe6a18ee1697436d1ca1cc0/astyle.el;
          sha256 = "1gvgijb810n8p954zswqj6vcl746x4zmqq7gsw13wykf04aqppgf";
        };
        buildInputs = with eSelf.melpaPackages; [
          reformatter
        ];
      };

      company-postgresql = compileEmacsFiles {
        name = "company-postgresql.el";
        src = builtins.fetchurl {
          url = https://raw.githubusercontent.com/urbint/emacs-postgresql-interactive/0c26f9cb4a7784c1eac121c30c557a70bff9b85e/company-postgresql.el;
          sha256 = "1znqdnz5dx2cil7pilpggl18jkalys0923k26iabqlab9apygi0z";
        };
        buildInputs = with eSelf.melpaPackages; [
          dash
          emacsql
          emacsql-psql
          s
        ];
      };

      etymology-of-word = compileEmacsFiles {
        name = "etymology-of-word.el";
        src = builtins.fetchurl {
          url = https://raw.githubusercontent.com/Camsbury/etymology-of-word/master/etymology-of-word.el;
          sha256 = "09yk4qrk3k5ygdqlj3ksdqzxh5532ychs4msphqrw3nim5dxhklw";
        };
        buildInputs = with eSelf.melpaPackages; [
          dash
        ];
      };

      ivy-cider = compileEmacsFiles {
        name = "ivy-cider.el";
        src = builtins.fetchurl {
          url = https://raw.githubusercontent.com/rschmukler/ivy-cider/206e12f3c0892539de0ec91667863effe1da878b/ivy-cider.el;
          sha256 = "0wiikh7l59c48bac6nlakai4p0dpi4qy7dlc6j2sr2gkznh5y5j0";
        };
        buildInputs = with eSelf.melpaPackages; [
          all-the-icons
          cider
          ivy
          ivy-rich
        ];
      };

      re-jump = compileEmacsFiles {
        name = "re-jump.el";
        src = builtins.fetchurl {
          url = https://raw.githubusercontent.com/oliyh/re-jump.el/443ddfa33dd2ae593cc0a013d16fff21f2afd925/re-jump.el;
          sha256 = "003zvvdlx77ncjml09gayspsrwynyqvhaip3cgzvn2nd92fwh9wk";
        };
        buildInputs = with eSelf.melpaPackages; [
          cider
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

      # slack = eSelf.melpaBuild {
      #   pname = "slack";
      #   version = "20190303.1037";
      #   src = super.fetchFromGitHub {
      #     owner = "yuya373";
      #     repo = "slack";
      #     rev = "5d37cb4aa8f1e100e2b0bed6193bd9d7df549637";
      #     sha256 = "1sw16474i2kav2bvg9r7zpfwkcbj3paymxi0jn9pdhgjyfm9bssk";
      #   };
      #   recipe = super.fetchurl {
      #     url = "https://github.com/melpa/melpa/blob/master/recipes/slack";
      #     sha256 = "0si9yyxyb681v4lxxc789xwdvk55gallwxbv3ldqfq4vjf0di0im";
      #     name = "recipe";
      #   };
      #   packageRequires = with eSelf.melpaPackages; [
      #     alert
      #     circe
      #     emojify
      #     eSelf.elpaPackages.oauth2
      #     request
      #     websocket
      #   ];
      #   meta = {
      #     homepage = "https://melpa.org/#/slack";
      #     license = super.stdenv.lib.licenses.free;
      #   };
      # };
    };
in
  {
    emacsPackagesNg = basePkgs.emacsPackagesNg.overrideScope' emacsOverrides;
  }

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

      clojure-essential-ref = eSelf.melpaBuild rec {
        pname = "clojure-essential-ref";
        version = "20200719.608";
        src = super.fetchFromGitHub {
          owner = "p3r7";
          repo = "clojure-essential-ref";
          rev = "3787300a2f6100d1a20b1259b488256f3a840fa6";
          sha256 = "08r5whs39r2fscicjzvmdfj7s7f49afhiz4i2i05ps1f1545569d";
        };
        packageRequires = with eSelf.melpaPackages; [
          cider
        ];
        recipe = builtins.toFile "recipe" # taken from the recipe link on melpa
          ''(clojure-essential-ref :repo "p3r7/clojure-essential-ref"
                       :fetcher github
                       :files (:defaults
                               (:exclude "clojure-essential-ref-nov.el")))
          '';
      };

      clojure-essential-ref-nov = eSelf.melpaBuild rec {
        pname = "clojure-essential-ref-nov";
        version = "20200719.608";
        src = super.fetchFromGitHub {
          owner = "p3r7";
          repo = "clojure-essential-ref";
          rev = "3787300a2f6100d1a20b1259b488256f3a840fa6";
          sha256 = "08r5whs39r2fscicjzvmdfj7s7f49afhiz4i2i05ps1f1545569d";
        };
        packageRequires = with eSelf.melpaPackages; [
          dash
          nov
          eSelf.clojure-essential-ref
        ];
        recipe = builtins.toFile "recipe" # taken from the recipe link on melpa
          ''(clojure-essential-ref-nov :repo "p3r7/clojure-essential-ref"
                           :fetcher github
                           :files (:defaults
                                   (:exclude "clojure-essential-ref.el")))
          '';
      };
    };
in
  {
    emacsPackagesNg = basePkgs.emacsPackagesNg.overrideScope' emacsOverrides;
  }

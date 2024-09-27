self: super:

let
  basePkgs = (
    import ../utils/unstable.nix { config = {allowUnfree = true;}; }
  );
  # Would be sweet to use the ones from nixpkgs instead
  compileEmacsFiles = basePkgs.callPackage ./emacsBuilder.nix;
  emacsOverrides = eSelf: eSuper:
    {
      asoc-el = compileEmacsFiles {
        name = "asoc.el";
        src = builtins.fetchurl {
          url = https://raw.githubusercontent.com/troyp/asoc.el/4a3309a9f250656da6f4a9d34feedf4f5666b17a/asoc.el;
          sha256 = "1fdynjy8xmx4a41982793z9329121k2bzigpm4vljx1yflq52v2b";
        };
      };

      # clojure-essential-ref = eSelf.melpaBuild rec {
      #   pname = "clojure-essential-ref";
      #   version = "20200719.608";
      #   src = super.fetchFromGitHub {
      #     owner = "p3r7";
      #     repo = "clojure-essential-ref";
      #     rev = "3787300a2f6100d1a20b1259b488256f3a840fa6";
      #     sha256 = "08r5whs39r2fscicjzvmdfj7s7f49afhiz4i2i05ps1f1545569d";
      #   };
      #   packageRequires = with eSelf.melpaPackages; [
      #     cider
      #   ];
      #   recipe = builtins.toFile "recipe" # taken from the recipe link on melpa
      #     ''(clojure-essential-ref :repo "p3r7/clojure-essential-ref"
      #                  :fetcher github
      #                  :files (:defaults
      #                          (:exclude "clojure-essential-ref-nov.el")))
      #     '';
      # };

      # clojure-essential-ref-nov = eSelf.melpaBuild rec {
      #   pname = "clojure-essential-ref-nov";
      #   version = "20200719.608";
      #   src = super.fetchFromGitHub {
      #     owner = "p3r7";
      #     repo = "clojure-essential-ref";
      #     rev = "3787300a2f6100d1a20b1259b488256f3a840fa6";
      #     sha256 = "08r5whs39r2fscicjzvmdfj7s7f49afhiz4i2i05ps1f1545569d";
      #   };
      #   packageRequires = with eSelf.melpaPackages; [
      #     dash
      #     nov
      #     eSelf.clojure-essential-ref
      #   ];
      #   recipe = builtins.toFile "recipe" # taken from the recipe link on melpa
      #     ''(clojure-essential-ref-nov :repo "p3r7/clojure-essential-ref"
      #                      :fetcher github
      #                      :files (:defaults
      #                              (:exclude "clojure-essential-ref.el")))
      #     '';
      # };

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
          url = https://raw.githubusercontent.com/emacsmirror/emacswiki.org/601b51e25e758083e66fab433cf61d22713fed51/hide-comnt.el;
          sha256 = "0v3wgl9r9w0qbvs1cxgl7am9hvpy6hyhvfbsjqix5n0zmdg68s4n";
        };
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
    };

in
  {
    emacsPackages = basePkgs.emacsPackages.overrideScope emacsOverrides;
  }

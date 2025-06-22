self: super:

let
  basePkgs = (
    import ../utils/unstable.nix { config = {allowUnfree = true;}; }
  );
  # Would be sweet to use the ones from nixpkgs instead
  compileEmacsFiles = basePkgs.callPackage ./emacsBuilder.nix;
  emacsOverrides = eSelf: eSuper:
    {
      melpaPackages = eSuper.melpaPackages // {
        aidermacs = eSelf.melpaBuild {
          pname = "aidermacs";
          version = "1.4";
          recipe = builtins.toFile "recipe.el" ''
            (aidermacs :fetcher github :repo "MatthewZMD/aidermacs")
          '';
          buildInputs = with eSelf.melpaPackages; [
            eSelf.elpaPackages.compat
            markdown-mode
            transient
          ];

          src = super.fetchFromGitHub {
            owner = "MatthewZMD";
            repo = "aidermacs";
            rev = "v1.4";
            hash = "sha256-ewvfBTxQuXw8BB0odey54ObXc/SiIPJzAm/MJ4TItYY=";
          };
        };
        cider = eSelf.melpaBuild {
          pname = "cider";
          version = "1.18.0";

          recipe = builtins.toFile "recipe.el" ''
            (cider :fetcher github
                   :repo "clojure-emacs/cider"
                   :files (;; new code layout:
                           "lisp/*.el" "bin/*.sh"
                           ;; old code layout - will be kept for a while during the transition:
                           "*.el" "clojure.sh" "lein.sh" (:exclude ".dir-locals.el"))
                   :old-names (nrepl))
          '';
          buildInputs = with eSelf.melpaPackages; [
            clojure-mode
            eSelf.elpaPackages.queue
            eSelf.elpaPackages.seq
            eSelf.elpaPackages.spinner
            parseedn
            sesman
            transient
          ];

          src = super.fetchFromGitHub {
            owner = "clojure-emacs";
            repo = "cider";
            rev = "v1.18.0";
            hash = "sha256-qgFmyPGpjUhMbIFGMYBzrlmrKj+/EnszNwVe4FlhmWU=";
          };
        };
      };

      asoc-el = compileEmacsFiles {
        name = "asoc.el";
        src = builtins.fetchurl {
          url = https://raw.githubusercontent.com/troyp/asoc.el/4a3309a9f250656da6f4a9d34feedf4f5666b17a/asoc.el;
          sha256 = "1fdynjy8xmx4a41982793z9329121k2bzigpm4vljx1yflq52v2b";
        };
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

      re-jump = compileEmacsFiles {
        name = "re-jump.el";
        src = builtins.fetchurl {
          url = https://raw.githubusercontent.com/oliyh/re-jump.el/443ddfa33dd2ae593cc0a013d16fff21f2afd925/re-jump.el;
          sha256 = "003zvvdlx77ncjml09gayspsrwynyqvhaip3cgzvn2nd92fwh9wk";
        };
        buildInputs = with eSelf.melpaPackages; with eSelf.elpaPackages; [
          cider
          clojure-mode
          parseclj
          parseedn
          queue
          sesman
          spinner
        ];
      };
    };

in
  {
    emacsPackages = basePkgs.emacsPackages.overrideScope emacsOverrides;
  }

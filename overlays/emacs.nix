self: super:

let
  basePkgs = (
    if super.stdenv.hostPlatform.system == "x86_64-linux"
    then import ../unstable.nix { config = {allowUnfree = true;}; }
    else super
  );
  machine = import ../machine.nix;
  # Would be sweet to use the ones from nixpkgs instead
  compileEmacsFiles = basePkgs.callPackage ./emacsBuilder.nix;
  emacsOverrides = eSelf: eSuper:
    {
      org-clubhouse = compileEmacsFiles {
        name = "org-clubhouse.el";
        src = builtins.fetchurl {
          url = https://raw.githubusercontent.com/urbint/org-clubhouse/master/org-clubhouse.el;
          sha256 = "1jckhdmq5jn95l0wyydj13k7c121yf921mm9k869ac8jsqrxpgz4";
        };
        buildInputs = with eSelf.melpaPackages; [
          dash
          dash-functional
          s
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

      key-quiz = compileEmacsFiles {
        name = "key-quiz.el";
        src = builtins.fetchurl {
          url = https://raw.githubusercontent.com/federicotdn/key-quiz/master/key-quiz.el;
          sha256 = "06v5l5nkzhxrxnmbc7vrmzmr9vwcqz68450gz3k6d2why3860cyf";
        };
      };

      # cider = eSelf.melpaBuild {
      #   pname = "cider";
      #   version = "20190226.1059";
      #   src = super.fetchFromGitHub {
      #     owner = "clojure-emacs";
      #     repo = "cider";
      #     rev = "dafb08cd429e622fb49aaf84df8491d04d8512f8";
      #     sha256 = "1sw16474i2kav2bvg9r7zpfwkcbj3paymxi0jn9pdhgjyfm9bssk";
      #   };
      #   recipe = super.fetchurl {
      #     url = "https://github.com/melpa/melpa/blob/master/recipes/cider";
      #     sha256 = "0si9yyxyb681v4lxxc789xwdvk55gallwxbv3ldqfq4vjf0di0im";
      #     name = "recipe";
      #   };
      #   packageRequires = with eSelf; [
      #     emacs
      #     pkg-info
      #     sesman
      #   ];
      #   meta = {
      #     homepage = "https://melpa.org/#/cider";
      #     license = super.stdenv.lib.licenses.free;
      #   };
      # };

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

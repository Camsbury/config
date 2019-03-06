pkgs: self: super:

let
  machine = import ./machine.nix;

  compileEmacsFiles = pkgs.callPackage ./builder.nix;

  org-clubhouse = compileEmacsFiles {
    name = "org-clubhouse.el";
    src = builtins.fetchurl {
      url = https://raw.githubusercontent.com/urbint/org-clubhouse/master/org-clubhouse.el;
      sha256 = "0njpad948l7bfkw5r30r7nz960ik2rmb0dyb46s40lab06ragc9l";
    };
    buildInputs = with self.melpaPackages; [
      dash
      dash-functional
      s
    ];
  };

  etymology-of-word = compileEmacsFiles {
    name = "etymology-of-word.el";
    src = builtins.fetchurl {
      url = https://raw.githubusercontent.com/Camsbury/etymology-of-word/master/etymology-of-word.el;
      sha256 = "09yk4qrk3k5ygdqlj3ksdqzxh5532ychs4msphqrw3nim5dxhklw";
    };
    buildInputs = with self.melpaPackages; [
      dash
    ];
  };

  cider = self.melpaBuild {
      pname = "cider";
      version = "20190226.1059";
      src = pkgs.fetchFromGitHub {
        owner = "clojure-emacs";
        repo = "cider";
        rev = "dafb08cd429e622fb49aaf84df8491d04d8512f8";
        sha256 = "1sw16474i2kav2bvg9r7zpfwkcbj3paymxi0jn9pdhgjyfm9bssk";
      };
      recipe = pkgs.fetchurl {
        url = "https://github.com/melpa/melpa/blob/master/recipes/cider";
        sha256 = "0si9yyxyb681v4lxxc789xwdvk55gallwxbv3ldqfq4vjf0di0im";
        name = "recipe";
      };
      packageRequires = with self; [
        emacs
        pkg-info
        sesman
      ];
      meta = {
        homepage = "https://melpa.org/#/cider";
        license = pkgs.stdenv.lib.licenses.free;
      };
    };

  slack = self.melpaBuild {
      pname = "slack";
      version = "20190303.1037";
      src = pkgs.fetchFromGitHub {
        owner = "yuya373";
        repo = "slack";
        rev = "5d37cb4aa8f1e100e2b0bed6193bd9d7df549637";
        sha256 = "1sw16474i2kav2bvg9r7zpfwkcbj3paymxi0jn9pdhgjyfm9bssk";
      };
      recipe = pkgs.fetchurl {
        url = "https://github.com/melpa/melpa/blob/master/recipes/slack";
        sha256 = "0si9yyxyb681v4lxxc789xwdvk55gallwxbv3ldqfq4vjf0di0im";
        name = "recipe";
      };
      packageRequires = with self.melpaPackages; [
        alert
        circe
        emojify
        self.elpaPackages.oauth2
        request
        websocket
      ];
      meta = {
        homepage = "https://melpa.org/#/slack";
        license = pkgs.stdenv.lib.licenses.free;
      };
    };
in
  {
    inherit org-clubhouse;
    inherit etymology-of-word;
  } // (if machine.darwin then {
    # inherit slack;
    # inherit cider;
  } else {})

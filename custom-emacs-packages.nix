pkgs: self: super:

let
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
in
{
  inherit org-clubhouse;
  inherit etymology-of-word;
}

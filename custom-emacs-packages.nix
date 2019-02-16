pkgs: self: super:

let
  compileEmacsFiles = pkgs.callPackage ./builder.nix;
  org-clubhouse = compileEmacsFiles {
    name = "org-clubhouse.el";
    src = builtins.fetchurl {
      url = https://raw.githubusercontent.com/urbint/org-clubhouse/master/org-clubhouse.el;
      sha256 = "0c52bf314sh3gdl8hs0lwqgwqdj42f87ifhhl1pdig7qk3951sgn";
    };
    buildInputs = with self.melpaPackages; [
      dash
      dash-functional
      s
    ];
  };
in
{
  inherit org-clubhouse;
}

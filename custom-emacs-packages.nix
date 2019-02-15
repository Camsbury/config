pkgs: self: super:

let
  compileEmacsFiles = pkgs.callPackage ./builder.nix;
  org-clubhouse = compileEmacsFiles {
    name = "org-clubhouse.el";
    src = builtins.fetchurl {
      url = https://raw.githubusercontent.com/urbint/org-clubhouse/master/org-clubhouse.el;
      sha256 = "04h8hj81gw6q8zd68r07aq7shrr99jlw1525kilh608n2g1zff2j";
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

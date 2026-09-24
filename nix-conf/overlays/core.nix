{
  config,
  pkgs,
  sources,
  ...
}:

let
  unstablePkgs = import sources.nixpkgs-unstable {
    config = {
      allowUnfree = true;
    };
  };
in
{
  nixpkgs.overlays = [
    (
      self: super:
      with builtins;
      with pkgs;
      {

        alias-tips = callPackage (import ../derivations/alias-tips) { };
        check-low-battery = callPackage (import ../derivations/check-low-battery) { };
        cmacs = callPackage (import ../derivations/cmacs) { };
        # The Emacs and package set cmacs runs.  Every consumer of that
        # set uses this attribute, so the build-time checks test what
        # actually runs.
        cmacs-emacs = emacsPackages.emacsWithPackages (import ../packages/emacs.nix);
        cmacs-eca-upstream-guard = callPackage (import ../derivations/cmacs-eca-upstream-guard) { };
        cmacs-load-path = callPackage (import ../derivations/cmacs-load-path) { };
        peon-ping = callPackage (import ../derivations/peon-ping) {
          src = sources.peon-ping.outPath;
        };
        pgn-extract = callPackage (import ../derivations/pgn-extract) { };
      }
      // (with unstablePkgs; {
        inherit bat;
        inherit discord;
        inherit emacs;
        inherit lmstudio;
        inherit mu;
        inherit netdata;
        inherit ouch;
        inherit spotify;
        emacsPackages = unstablePkgs.emacsPackages.overrideScope (import ./emacs.nix unstablePkgs);
      })
    )
  ];
}

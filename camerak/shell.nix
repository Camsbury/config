let
  pkgs = import ./pinned.nix {
    overlays = [(import ./overlays.nix)];
  };
in
pkgs.mkShell {
  name = "flashErgodox";
  buildInputs = [(import ./default.nix).flash];
}

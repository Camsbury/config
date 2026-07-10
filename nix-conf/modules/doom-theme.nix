{ pkgs }:

# Shared doom-molokam theme data for the lock screen (screen_lock.nix) and the
# login greeter (login_greeter.nix), so lock and login paint one palette and one
# wallpaper from a single source of truth.
#
# This is NOT a NixOS module: it takes `{ pkgs }` and returns `{ palette;
# wallpaper; }`. Import it in a `let`; never add it to an `imports` list.

let
  # doom-molokam palette, parsed straight from the theme EDN at eval time. Each
  # palette line reads `:name ["#rrggbb" ...]`; we pull the first (GUI) hex per
  # name, WITHOUT the leading '#'. A palette rename fails the build loudly
  # (missing-attribute at the use site) rather than theming the UI wrong.
  palette =
    let
      lines = builtins.filter builtins.isString (
        builtins.split "\n" (builtins.readFile ../../emacs-conf/config/theme/doom-molokam.edn)
      );
      entry =
        line:
        let
          m = builtins.match ".*:([a-zA-Z0-9-]+)[[:space:]]+\\[\"#([0-9a-fA-F]{6})\".*" line;
        in
        if m == null then
          null
        else
          {
            name = builtins.elemAt m 0;
            value = builtins.elemAt m 1;
          };
    in
    builtins.listToAttrs (builtins.filter (x: x != null) (map entry lines));
in
{
  inherit palette;

  # Shared background image. Swap this for any PNG on disk, e.g.
  #   wallpaper = /home/me/pictures/lock.png;
  # or another nixos-artwork wallpaper (see `pkgs.nixos-artwork.wallpapers`), to
  # change BOTH the lock screen and the login screen at once.
  wallpaper = "${pkgs.nixos-artwork.wallpapers.simple-dark-gray}/share/backgrounds/nixos/nix-wallpaper-simple-dark-gray.png";
}

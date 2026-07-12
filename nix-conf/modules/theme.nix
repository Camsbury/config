{
  config,
  lib,
  pkgs,
  ...
}:

# Shared desktop theme: the doom-molokam palette plus ONE processed wallpaper,
# consumed by both the lock screen (screen_lock.nix) and the login greeter
# (login_greeter.nix) so the two paint one palette over one background.
#
# This is a proper NixOS module. It exposes `ck.theme.palette` and
# `ck.theme.wallpaper` as options; read them through `config.ck.theme.*` in the
# consumers (no `import`). It supersedes the old non-module doom-theme.nix
# (decision 0014): the wallpaper PROCESSING (recolor to black, cover-scale to
# the panel) now lives here once, so lock and login share the identical image
# rather than the greeter scaling its own copy.

let
  # doom-molokam palette parsed straight from the theme EDN at eval time. Each
  # palette line reads `:name ["#rrggbb" ...]`; we pull the first (GUI) hex per
  # name WITHOUT the leading '#'. A palette rename fails the build loudly
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

  # Panel resolution for poseidon's DP-0. The mini greeter draws its background
  # CENTERED and UNSCALED, so the shared image must already be panel-sized to
  # fill; the locker's `--fill` then no-ops on an already-panel-sized image.
  # Host-specific; bump if the panel changes.
  screenRes = "3840x2160";

  # The login greeter's password box is hardcoded to screen center (mini-greeter
  # src/ui.c place_main_window; no offset config exists), so to keep the logo
  # VISIBLE there we move the logo instead of the box. Shift the base image up
  # `logoShift` px (padding the bottom black, which is invisible on the pure-
  # black field) so the dead-center logo (at 50% of screen height) rises clear
  # above the centered box; a larger value lifts it higher. In base 1920x1080
  # px; scaled x2 at the 4K panel. ONLY the greeter needs this; the lock screen
  # keeps the logo centered (it looks better, and i3lock's ring/clock sit over
  # it fine), so the shift is a greeter-only variant, not the canonical image.
  logoShift = 100;

  # Base image, a nixos-artwork gradient. Swap this path (or the processing
  # below) to restyle BOTH screens at once.
  baseWallpaper = "${pkgs.nixos-artwork.wallpapers.simple-dark-gray}/share/backgrounds/nixos/nix-wallpaper-simple-dark-gray.png";

  # Build a processed wallpaper. Three transforms, in order:
  #   1. `-black-threshold 40%`: the base is a dark-gray radial gradient (~18%
  #      at the edges to ~33% at the center) with a bright NixOS logo. Blacken
  #      every pixel below 40% luminance, which is the whole gray field, and
  #      LEAVE the logo (its bright pixels sit above 40%). Result: pure-black
  #      background, logo kept.
  #   2. shift the logo up by `shift` px: crop the top off and pad the same
  #      amount of black at the bottom, lifting the logo above dead center. Must
  #      come AFTER the blacken so the padded strip is pure black, and BEFORE
  #      the resize so the shift is in base px. `shift = 0` is a no-op (crop
  #      1920x1080+0+0 then extent 1920x1080), leaving the logo centered.
  #   3. cover-fit to the panel: the greeter's centered-unscaled draw (and the
  #      locker's `--fill`) needs a panel-sized image to fill edge to edge.
  mkWallpaper =
    { name, shift }:
    pkgs.runCommand name { } ''
      ${pkgs.imagemagick}/bin/magick ${baseWallpaper} \
        -black-threshold 40% \
        -gravity North -background black \
        -crop 1920x${toString (1080 - shift)}+0+${toString shift} +repage \
        -extent 1920x1080 \
        -resize ${screenRes}^ -gravity center -extent ${screenRes} \
        png:$out
    '';

  # Canonical wallpaper: logo dead-centered. Used by the lock screen.
  wallpaper = mkWallpaper {
    name = "desktop-wallpaper.png";
    shift = 0;
  };

  # Greeter-only variant: same image with the logo lifted clear of the
  # hardcoded centered password box.
  wallpaperLogoShifted = mkWallpaper {
    name = "desktop-wallpaper-logo-shifted.png";
    shift = logoShift;
  };
in
{
  options.ck.theme = {
    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      description = ''
        doom-molokam colors as `name -> "rrggbb"` (no leading '#'), parsed from
        the Emacs theme EDN so the desktop and editor share one source.
      '';
    };
    wallpaper = lib.mkOption {
      type = lib.types.path;
      readOnly = true;
      description = ''
        The canonical processed wallpaper: pure-black background (logo
        dead-centered, kept), cover-scaled to the panel. Used by the lock
        screen.
      '';
    };
    wallpaperLogoShifted = lib.mkOption {
      type = lib.types.path;
      readOnly = true;
      description = ''
        Same as `wallpaper` but with the logo lifted `logoShift` px so it
        clears the mini-greeter's hardcoded centered password box. Used by the
        login greeter only.
      '';
    };
  };

  config.ck.theme = {
    inherit palette wallpaper wallpaperLogoShifted;
  };
}

{ config, pkgs, ... }:

# Minimal LightDM login screen via lightdm-mini-greeter: one centered password
# box on the shared wallpaper, colored from the doom-molokam palette so the
# LOGIN screen mirrors the i3lock lock screen (screen_lock.nix). No embedded
# browser and no custom derivation; the greeter is a small GTK app already in
# nixpkgs that reads a single /etc/lightdm/lightdm-mini-greeter.conf.
#
# It starts only the DEFAULT X session (services.displayManager.defaultSession =
# "none+exwm", set in exwm.nix), which is exactly what we want.
#
# Recovery: if login ever breaks, switch to a TTY (Ctrl+Alt+F2), log in, comment
# out the greeter block below to fall back to the default gtk greeter, and
# rebuild (or `systemctl restart display-manager` after fixing).

let
  theme = import ./doom-theme.nix { inherit pkgs; };
  palette = theme.palette;

  # doom-molokam hexes (without '#'); same colors the locker ring uses.
  fg = palette.fg; # label text + typed password glyphs
  bg = palette.bg; # box fill + fallback behind the wallpaper
  grey = palette.grey; # password-field border (i3lock idle ring)
  blue = palette.blue; # login-box border accent (i3lock typing/verify color)
  red = palette.red; # invalid-password text

  # lightdm-mini-greeter reads this hardcoded path. The [greeter-theme] keys are
  # exactly those the nixpkgs mini module writes, recolored to the doom palette;
  # hex values must be quoted and '#'-prefixed.
  miniConf = pkgs.writeText "lightdm-mini-greeter.conf" ''
    [greeter]
    user = camsbury
    show-password-label = true
    password-label-text = Password:
    invalid-password-text = nope
    show-input-cursor = true
    password-alignment = left

    [greeter-hotkeys]
    mod-key = meta
    shutdown-key = s
    restart-key = r
    hibernate-key = h
    suspend-key = u

    [greeter-theme]
    font = monospace
    font-size = 1.2em
    font-weight = bold
    font-style = normal
    text-color = "#${fg}"
    error-color = "#${red}"
    background-image = "${theme.wallpaper}"
    background-color = "#${bg}"
    window-color = "#${bg}"
    border-color = "#${blue}"
    border-width = 2px
    layout-space = 15
    password-color = "#${fg}"
    password-background-color = "#${bg}"
    password-border-color = "#${grey}"
    password-border-width = 2px
  '';
in
{
  services.xserver.displayManager.lightdm = {
    # Only one greeter runs at a time; turn off the default gtk greeter.
    greeters.gtk.enable = false;

    greeter = {
      package = pkgs.lightdm-mini-greeter.xgreeters;
      name = "lightdm-mini-greeter";
    };
  };

  environment.etc."lightdm/lightdm-mini-greeter.conf".source = miniConf;
}

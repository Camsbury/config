{ config, pkgs, ... }:

# Media-key routing, independent of the screen locker.
#
# The hardware XF86Audio* keys used to be EXWM global bindings that shelled out
# to Spotify over D-Bus. Two problems: they were hardcoded to one player, and
# any locker grabs the X keyboard, so they died while the screen was locked.
#
# Fix, in two parts:
#   playerctl + playerctld  route transport keys over MPRIS to whatever player
#                           was most recently active (Spotify, mpv, a browser,
#                           anything), instead of naming a player.
#   triggerhappy            an evdev hotkey daemon that reads /dev/input below
#                           X, so it fires the same commands whether or not a
#                           locker holds the X keyboard grab. This is why the
#                           keys keep working while locked. (i3lock-color's own
#                           --pass-media-keys forwards synthetic XSendEvent
#                           events, which do NOT trigger EXWM's passive key
#                           grabs, so it cannot drive the EXWM bindings; reading
#                           evdev directly avoids the whole grab question.)
#
# Because triggerhappy owns these keys unconditionally, they are removed from
# the EXWM bindings (emacs-conf/core/desktop.el) to avoid double-firing.

let
  username = toString config.users.users.default.name;
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  wpctl = "${pkgs.wireplumber}/bin/wpctl";

  # triggerhappy runs thd as `username` (unprivileged; udev feeds it evdev fds),
  # but with a bare service environment. playerctl and wpctl need the user's
  # session bus and runtime dir, so each media action is a small wrapper that
  # sets them first. `id -u` resolves the uid at runtime (thd already runs as
  # the user), so nothing is pinned to a specific machine's uid.
  mkMedia =
    name: cmd:
    pkgs.writeShellScript name ''
      export XDG_RUNTIME_DIR="/run/user/$(${pkgs.coreutils}/bin/id -u)"
      export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
      exec ${cmd}
    '';

  playPause = mkMedia "media-play-pause" "${playerctl} play-pause";
  prev = mkMedia "media-prev" "${playerctl} previous";
  next = mkMedia "media-next" "${playerctl} next";
  mute = mkMedia "media-mute" "${wpctl} set-mute @DEFAULT_SINK@ toggle";
  # -l 1.0 caps volume at 100% so repeated raises cannot drive it into clipping.
  volUp = mkMedia "media-vol-up" "${wpctl} set-volume -l 1.0 @DEFAULT_SINK@ 5%+";
  volDown = mkMedia "media-vol-down" "${wpctl} set-volume @DEFAULT_SINK@ 5%-";
in
{
  environment.systemPackages = [ pkgs.playerctl ];

  # Tracks MPRIS player activity so plain `playerctl` acts on the most recently
  # active player. Runs under the user's systemd manager, so it shares the
  # session bus with both the players and the triggerhappy wrappers.
  systemd.user.services.playerctld = {
    description = "playerctld (route media keys to the active MPRIS player)";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.playerctl}/bin/playerctld daemon";
      Restart = "always";
    };
  };

  # evdev hotkey daemon. Key names are from linux/input-event-codes.h (the
  # module prefixes KEY_). Volume up/down are bound on press AND hold so holding
  # the key ramps, matching the old X autorepeat behavior.
  services.triggerhappy = {
    enable = true;
    user = username;
    bindings = [
      {
        keys = [ "PLAYPAUSE" ];
        cmd = "${playPause}";
      }
      {
        keys = [ "PREVIOUSSONG" ];
        cmd = "${prev}";
      }
      {
        keys = [ "NEXTSONG" ];
        cmd = "${next}";
      }
      {
        keys = [ "MUTE" ];
        cmd = "${mute}";
      }
      {
        keys = [ "VOLUMEUP" ];
        event = "press";
        cmd = "${volUp}";
      }
      {
        keys = [ "VOLUMEUP" ];
        event = "hold";
        cmd = "${volUp}";
      }
      {
        keys = [ "VOLUMEDOWN" ];
        event = "press";
        cmd = "${volDown}";
      }
      {
        keys = [ "VOLUMEDOWN" ];
        event = "hold";
        cmd = "${volDown}";
      }
    ];
  };
}

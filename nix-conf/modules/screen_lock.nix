{ config, pkgs, ... }:

# Screen locking, three cooperating pieces:
#
#   xss-lock     the logind bridge. Runs the locker on `loginctl lock-session`
#                and, crucially, holds a sleep inhibitor until the locker is up
#                before suspend (--transfer-sleep-lock), so no unlocked frame
#                flashes on wake. It also locks when the X screensaver
#                activates (the X server's built-in `xset s 600` timeout), our
#                guaranteed 10-minute fallback lock.
#   i3lock-color the locker itself: a themed ring + clock over a static
#                background image (PAM auth via the `login` service). Driven by
#                the lock script below.
#   xidlehook    the primary idle timer. Locks after 5 min idle, then blanks the
#                monitor via DPMS 5 min after that (second chained timer), BUT
#                skips both while a fullscreen app runs or audio plays, so
#                video/music aren't interrupted. It reads the X screensaver idle
#                counter, so the `xset s` timeout above must stay non-zero (never
#                `xset s off`). NOTE: `xset dpms` is a SEPARATE subsystem from
#                the `xset s` screensaver counter, so the DPMS timer does not
#                touch the idle counter xidlehook relies on.
#
# Manual lock is `loginctl lock-session` (see ck/lock-screen in emacs-conf),
# routed through xss-lock so there is a single locker of record.
#
# The lock script also pauses dunst (`dunstctl set-paused`) for the locked
# span, so no notification content paints on the lock screen; queued
# notifications pop on unlock. Restored via an EXIT trap so a crashed locker
# never strands dunst paused.
#
# Media keys while locked are NOT handled here. i3lock-color grabs the X
# keyboard, so EXWM's media bindings die while locked; the fix lives in
# media_keys.nix, which reads evdev below X and works regardless of the grab.

let
  # Shared doom-molokam palette + wallpaper from the ck.theme module
  # (modules/theme.nix), so the lock screen and the login greeter paint one
  # palette over one background. `palette` maps each `:name` to its first (GUI)
  # hex WITHOUT the leading '#'; a palette rename fails the build loudly at the
  # use site. Colors feed i3lock-color as RRGGBBAA (an alpha byte is appended at
  # each use site below). The wallpaper is already pure-black and panel-sized,
  # so `--fill` below just no-ops (a guard for odd panel sizes).
  wallpaper = config.ck.theme.wallpaper;
  palette = config.ck.theme.palette;

  bg = palette.bg; # base black: inside circle
  fg = palette.fg; # foreground text: clock/date
  grey = palette.grey; # idle ring
  green = palette.green; # verifying
  blue = palette.blue; # verify text
  red = palette.red; # wrong
  magenta = palette.magenta; # keypress highlight
  yellow = palette.yellow; # backspace highlight
  violet = palette.violet; # separators

  # The locker command. Adapted from xss-lock's shipped
  # transfer-sleep-lock-i3lock.sh: with a sleep-lock fd we run i3lock-color in
  # its forking mode (no -n), close the fd once it has grabbed the screen to
  # release the suspend inhibitor, then poll until it exits. NOTE: the binary
  # is `i3lock-color`, so pkill must match that exact name, not `i3lock`.
  lockCmd = pkgs.writeShellScript "i3lock-color-lock" ''
    set -u
    i3lock="${pkgs.i3lock-color}/bin/i3lock-color"
    pkill="${pkgs.procps}/bin/pkill"
    sleep="${pkgs.coreutils}/bin/sleep"
    dunstctl="${pkgs.dunst}/bin/dunstctl"

    # Pause dunst for the whole locked span so no notification content paints on
    # the lock screen. Paused notifications queue and pop on unlock (and stay in
    # history); nothing is lost. The EXIT trap restores dunst however we leave
    # (normal exit, or TERM/INT from xss-lock), so a crashed locker can't strand
    # dunst paused. EXIT is a different trap slot from the per-branch TERM/INT
    # traps below, so the two coexist. `|| true` keeps a dunst/D-Bus hiccup from
    # aborting the locker under `set -u`/pipefail-free but defensive anyway.
    "$dunstctl" set-paused true || true
    trap '"$dunstctl" set-paused false || true' EXIT

    opts=(
      --image=${wallpaper} --fill --color=${bg}ff
      --clock --indicator
      --radius=110 --ring-width=8
      --inside-color=${bg}cc
      --ring-color=${grey}ff
      --insidever-color=${bg}cc
      --ringver-color=${green}ff
      --insidewrong-color=${bg}cc
      --ringwrong-color=${red}ff
      --line-uses-inside
      --keyhl-color=${magenta}ff
      --bshl-color=${yellow}ff
      --separator-color=${violet}ff
      --verif-color=${blue}ff
      --wrong-color=${red}ff
      --time-color=${fg}ff
      --date-color=${fg}ff
      --time-str=%H:%M
      --date-str=%A %B %-d
      --time-size=48
      --date-size=20
      --verif-text=verifying...
      --wrong-text=nope
      --noinput-text=
      --pointer=default
    )

    kill_locker() { "$pkill" -xu "$EUID" "$@" i3lock-color; }

    if [[ -e /dev/fd/''${XSS_SLEEP_LOCK_FD:--1} ]]; then
      trap kill_locker TERM INT
      # Forking mode: parent exits once the screen is grabbed. Close the sleep
      # lock fd in the child so it is not inherited.
      "$i3lock" "''${opts[@]}" {XSS_SLEEP_LOCK_FD}<&-
      # Only copy of the fd left is ours; close it to signal ready-to-sleep.
      exec {XSS_SLEEP_LOCK_FD}<&-
      while kill_locker -0; do "$sleep" 0.5; done
    else
      trap 'kill %%' TERM INT
      "$i3lock" --nofork "''${opts[@]}" &
      wait
    fi
  '';

  # Blank the monitor via DPMS. i3lock-color has no DPMS of its own, so nothing
  # drops the video signal while locked and the panel stays fully powered (clock
  # just sitting there). This forces the signal off so the monitor enters its
  # own hardware power-save/idle state, the same "no signal" sleep it reaches on
  # its own; any keypress or mouse move wakes it back up. `+dpms` first in case
  # DPMS is disabled on the server, since `force off` is a no-op when it is.
  dpmsOff = pkgs.writeShellScript "dpms-off" ''
    ${pkgs.xset}/bin/xset +dpms
    ${pkgs.xset}/bin/xset dpms force off
  '';
in
{
  environment.systemPackages = [
    pkgs.xidlehook
  ];

  # Installs i3lock-color AND, via nixpkgs' pam.nix, creates the
  # `security.pam.services.i3lock` / `i3lock-color` PAM stacks (unix password
  # auth). Without this there is no /etc/pam.d/i3lock, so pam_start fails and
  # you cannot unlock. The locker binary authenticates against the `i3lock`
  # PAM service.
  programs.i3lock = {
    enable = true;
    package = pkgs.i3lock-color;
  };

  programs.xss-lock = {
    enable = true;
    lockerCommand = "${lockCmd}";
    extraOptions = [ "--transfer-sleep-lock" ];
  };

  # Never let xss-lock die permanently. It lives in the persistent `--user`
  # manager, but its X connection belongs to ONE graphical session; when that
  # session is torn down (a `ck/restart-display-manager`, the usual recovery
  # when the monitor won't wake, or any DM restart) xss-lock SIGABRTs on the
  # lost X connection. systemd then restarts it, but every retry during the
  # ~20s teardown + greeter-handover window hits "Authorization required, but no
  # authorization protocol specified": there is no connectable X yet. A bounded
  # start limit (even a widened one) burns its whole budget inside that window
  # and lands the unit in `failed (start-limit-hit)` for good, so the lock
  # binding silently no-ops (loginctl lock-session has no listener) until a
  # manual `reset-failed && restart`. Disabling the rate limiter entirely
  # (StartLimitIntervalSec=0) lets Restart=always keep retrying calmly every 2s
  # and reconnect the instant the new session's X + fresh ~/.Xauthority are
  # ready. Worst case it retries a dozen times harmlessly; it can never get
  # stuck dead. Domain-durable for any X11 box running xss-lock as a user
  # service across session restarts.
  systemd.user.services.xss-lock = {
    startLimitIntervalSec = 0;
    serviceConfig.RestartSec = "2s";
  };

  # Primary idle lock with fullscreen/audio guards. Fires before the 600s X
  # screensaver fallback, and triggers the same single locker path via logind.
  # A second, chained timer blanks the monitor (DPMS off) 300s AFTER the lock
  # fires (xidlehook timers are relative to the previous), i.e. 5 min after lock
  # / 600s total idle. Both timers inherit the fullscreen/audio guards, so a
  # movie or music neither locks nor blanks the screen. DISPLAY is inherited
  # from the graphical session, same as xss-lock.
  systemd.user.services.xidlehook = {
    description = "Idle screen locker (xidlehook -> loginctl lock-session)";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.xidlehook}/bin/xidlehook --not-when-fullscreen --not-when-audio --timer 300 '${pkgs.systemd}/bin/loginctl lock-session' '' --timer 300 '${dpmsOff}' ''";
      Restart = "always";
    };
  };
}

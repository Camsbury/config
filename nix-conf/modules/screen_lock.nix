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
#   xidlehook    the primary idle timer. Locks after 5 min idle BUT skips while
#                a fullscreen app runs or audio plays, so video/music aren't
#                interrupted. It reads the X screensaver idle counter, so the
#                `xset s` timeout above must stay non-zero (never `xset s off`).
#
# Manual lock is `loginctl lock-session` (see ck/lock-screen in emacs-conf),
# routed through xss-lock so there is a single locker of record.
#
# Media keys while locked are NOT handled here. i3lock-color grabs the X
# keyboard, so EXWM's media bindings die while locked; the fix lives in
# media_keys.nix, which reads evdev below X and works regardless of the grab.

let
  # Shared doom-molokam palette + wallpaper, so the lock screen and the login
  # greeter (login_greeter.nix) theme from one source. `palette` maps each
  # `:name` to its first (GUI) hex WITHOUT the leading '#'; a palette rename
  # fails the build loudly at the use site. Colors feed i3lock-color as
  # RRGGBBAA (an alpha byte is appended at each use site below).
  theme = import ./doom-theme.nix { inherit pkgs; };
  wallpaper = theme.wallpaper;
  palette = theme.palette;

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

  # Primary idle lock with fullscreen/audio guards. Fires before the 600s X
  # screensaver fallback, and triggers the same single locker path via logind.
  # DISPLAY is inherited from the graphical session, same as xss-lock.
  systemd.user.services.xidlehook = {
    description = "Idle screen locker (xidlehook -> loginctl lock-session)";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.xidlehook}/bin/xidlehook --not-when-fullscreen --not-when-audio --timer 300 '${pkgs.systemd}/bin/loginctl lock-session' ''";
      Restart = "always";
    };
  };
}

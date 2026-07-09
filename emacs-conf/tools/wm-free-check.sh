#!/usr/bin/env bash
#
# wm-free-check.sh -- boot the FULL cmacs config in a non-WM Emacs.
#
# Proves the whole config loads outside the window manager: everything except
# `exwm-wm-mode' itself (stubbed) must load in a plain graphical Emacs.  Runs
# on an isolated Xvfb display so the live session is never touched, using the
# SAME emacs binary, EMACSLOADPATH, and flags as the real `cmacs' launcher
# (resolved from the launcher at runtime; store paths rot, never hardcode).
#
# This is the load-side check for the editor-vs-WM seam: a regression here
# means some file grew a hard load-time WM dependency.
#
# Usage: tools/wm-free-check.sh        # exits 0 on PASS, 1 on FAIL
#
# See wm-free-check.el for what is stubbed and why the check is safe to run
# beside the live WM (no server socket, no shared state writes).

set -euo pipefail

launcher="$(readlink -f "$(command -v cmacs)")"
emacs_bin="$(grep -oE '/nix/store/[^ ]+/bin/emacs' "$launcher" | head -1)"
loadpath="$(grep -oE 'EMACSLOADPATH="[^"]*"' "$launcher" \
            | sed 's/^EMACSLOADPATH="//; s/"$//')"
config_path="$(grep -oE 'CONFIG_PATH=[^ ]+' "$launcher" | head -1 | cut -d= -f2)"
export EMACSLOADPATH="$loadpath"
export CONFIG_PATH="$config_path"
# SHAREPATH is session-provided, not launcher-provided; the config reads
# files under it at load (e.g. wc3 build orders), so it must be real.
: "${SHAREPATH:?SHAREPATH must be set in the environment}"

if [[ -z "$emacs_bin" || -z "$EMACSLOADPATH" || -z "$CONFIG_PATH" ]]; then
  echo "wm-free-check: could not resolve emacs/env from $launcher" >&2
  exit 2
fi

# isolated display
display=""
for d in 99 98 97 96; do
  [[ -e "/tmp/.X11-unix/X$d" ]] || { display=":$d"; break; }
done
[[ -n "$display" ]] || { echo "wm-free-check: no free X display" >&2; exit 2; }

result="$(mktemp --suffix=-wm-free-check.txt)"
export WM_FREE_CHECK_RESULT="$result"

Xvfb "$display" -screen 0 1600x1200x24 >/dev/null 2>&1 &
xvfb_pid=$!
trap 'kill "$xvfb_pid" 2>/dev/null || true; rm -f "$result"' EXIT
sleep 2

here="$(cd "$(dirname "$0")" && pwd)"
set +e
DISPLAY="$display" timeout 180 "$emacs_bin" \
  --no-site-file --no-site-lisp --no-init-file --no-splash \
  --load "$here/wm-free-check.el" >/dev/null 2>&1
ec=$?
set -e

echo "emacs exit=$ec ($([[ $ec -eq 124 ]] && echo timeout || echo done))"
echo "---"
cat "$result" 2>/dev/null || echo "NO RESULT FILE (crash or timeout)"
exit "$([[ $ec -eq 0 ]] && echo 0 || echo 1)"

#!/usr/bin/env bash
#
# eca-upstream-guard.sh -- the ECA-upstream-adapter drift guard.
#
# Fails when any upstream `eca-emacs' symbol wrapped by the ECA Upstream
# Adapter (config/services/eca/upstream.el) has vanished from the installed
# package: a rename upstream that would silently break a satellite.  The
# adapter is the one boundary we maintain by hand, so this keeps its wrapped
# symbol list honest mechanically.
#
# Resolves the emacs binary and EMACSLOADPATH from the real cmacs launcher
# (the ambient `emacs' is a different build; see gotchas), matching
# lib-guard.sh.  Pure batch: no X, no server, safe to run anytime.
#
# Usage: tools/eca-upstream-guard.sh   # exits 0 PASS, 1 FAIL, 2 setup-error

set -euo pipefail

launcher="$(readlink -f "$(command -v cmacs)")"
emacs_bin="$(grep -oE '/nix/store/[^ ]+/bin/emacs' "$launcher" | head -1)"
loadpath="$(grep -oE 'EMACSLOADPATH="[^"]*"' "$launcher" \
            | sed 's/^EMACSLOADPATH="//; s/"$//')"

if [[ -z "$emacs_bin" || -z "$loadpath" ]]; then
  echo "eca-upstream-guard: could not resolve emacs/env from $launcher" >&2
  exit 2
fi

export EMACSLOADPATH="$loadpath"
here="$(cd "$(dirname "$0")" && pwd)"
exec "$emacs_bin" -Q --batch --load "$here/eca-upstream-guard.el"

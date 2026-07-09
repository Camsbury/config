#!/usr/bin/env bash
#
# lib-guard.sh -- the library-seam guard (decision 0009, rollout step 6).
#
# Fails when any feature under lib/ classifies as application: lib/ is the
# wiring-free layer, pulled by `require' on demand, and this keeps it that
# way mechanically.  Classification is `cmacs-deps-classify' (load-time
# wiring heads vs pure definitions).
#
# Resolves the emacs binary and EMACSLOADPATH from the real cmacs launcher
# (the ambient `emacs' is a different build; see gotchas).  Pure batch: no
# X, no server, safe to run anytime.
#
# Usage: tools/lib-guard.sh    # exits 0 on PASS, 1 on FAIL

set -euo pipefail

launcher="$(readlink -f "$(command -v cmacs)")"
emacs_bin="$(grep -oE '/nix/store/[^ ]+/bin/emacs' "$launcher" | head -1)"
loadpath="$(grep -oE 'EMACSLOADPATH="[^"]*"' "$launcher" \
            | sed 's/^EMACSLOADPATH="//; s/"$//')"

if [[ -z "$emacs_bin" || -z "$loadpath" ]]; then
  echo "lib-guard: could not resolve emacs/env from $launcher" >&2
  exit 2
fi

export EMACSLOADPATH="$loadpath"
here="$(cd "$(dirname "$0")" && pwd)"
exec "$emacs_bin" -Q --batch --load "$here/lib-guard.el"

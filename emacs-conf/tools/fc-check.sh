#!/usr/bin/env bash
#
# fc-check.sh -- reproduce flycheck's emacs-lisp checker for one or more files.
#
# Flycheck byte-compiles each .el file in a fresh subprocess with the running
# session's `load-path' inherited (see config/langs/elisp.el, where we set
# `flycheck-emacs-lisp-load-path' to `inherit').  This script does the same
# from the shell so a file's warnings can be measured without opening it: a
# clean `emacs -Q' batch compile of a temp copy, with the live WM Emacs's
# `load-path' handed in.
#
# It is the acceptance test for the explicit-dependency refactor: a file is
# "done" when it byte-compiles clean in isolation (no load-order warnings).
#
# Usage:
#   tools/fc-check.sh FILE.el [FILE.el ...]
#   tools/fc-check.sh --summary FILE.el ...   # one line per file: counts
#
# Requires a running WM Emacs server (emacsclient) to source the load-path.

set -euo pipefail

summary=0
if [[ "${1:-}" == "--summary" ]]; then
  summary=1
  shift
fi

if [[ $# -eq 0 ]]; then
  echo "usage: fc-check.sh [--summary] FILE.el ..." >&2
  exit 2
fi

# Capture the live session's load-path once (includes emacs-conf/ + every Nix
# package dir).  emacsclient writes it as a `(setq load-path '(...))' form that
# the batch process loads before compiling.
lp="$(mktemp --suffix=.el)"
trap 'rm -f "$lp"' EXIT
if ! emacsclient --eval \
     "(with-temp-file \"$lp\" (prin1 \`(setq load-path ',load-path) (current-buffer)))" \
     >/dev/null 2>&1; then
  echo "fc-check: no live WM Emacs (emacsclient failed); start it first." >&2
  exit 1
fi

# Warning classes that are NOT load-order (out of scope for the dep refactor).
noise='docstring'

check_one () {
  local file="$1" tmp base out
  tmp="$(mktemp -d)"
  base="$(basename "$file")"
  cp "$file" "$tmp/$base"
  # NOTE: do NOT force `(setq byte-compile-warnings t)' here.  The default is
  # already t (all classes), and forcing it globally OVERRIDES a file's own
  # `;; byte-compile-warnings: (not unresolved)' file-local, so a hub that
  # legitimately suppresses the unresolved class would still report it - the
  # harness would not reflect what real byte-compilation / flycheck sees.
  out="$(emacs -Q --batch \
           --load "$lp" \
           -f batch-byte-compile "$tmp/$base" 2>&1 \
         | grep -E "Warning|Error" | sed "s#$tmp/##" || true)"
  rm -rf "$tmp"

  if [[ $summary -eq 1 ]]; then
    local total lo
    total="$(grep -c 'Warning' <<<"$out" || true)"
    lo="$(grep -Ec 'not known to be defined|might not be defined|free variable' <<<"$out" || true)"
    printf '%-55s total=%-3s load-order=%-3s\n' "$file" "${total:-0}" "${lo:-0}"
  else
    echo "=== $file ==="
    if [[ -n "$out" ]]; then echo "$out"; else echo "(clean)"; fi
  fi
}

for f in "$@"; do
  check_one "$f"
done

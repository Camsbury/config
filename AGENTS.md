# Camsbury/config

Personal machine configuration monorepo for the NixOS host `poseidon`:

- `nix-conf/`: NixOS modules, machines, derivations, package manifests.
- `emacs-conf/`: **cmacs**, the Emacs + EXWM config (Emacs is the window
  manager). Deps are Nix-built; there is no runtime package management.
- `manage_browser_links.clj`, `dunstrc`, etc.: supporting host config.

Host-specific by design; portability is not a goal.

## Agent docs

Supplemental docs live at `.eca/docs/` (start at `.eca/docs/README.md`; use
the `orient` and `handoff` skills). `.eca/` is invisible to grep and
directory-tree tools, so read them by exact path. The whole `.eca/` dir is
gitignored here: a fresh clone will not have these docs; fall back to the
README and source.

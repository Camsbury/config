# Camsbury/config

Personal machine configuration monorepo for the NixOS host `poseidon`:

- `nix-conf/`: NixOS modules, machines, derivations, package manifests.
- `emacs-conf/`: **cmacs**, the Emacs + EXWM config (Emacs is the window
  manager). Deps are Nix-built; there is no runtime package management.
- `manage_browser_links.clj`, `dunstrc`, etc.: supporting host config.

Host-specific by design; portability is not a goal.

## Agent skills

### Issue tracker

Issues live as local Markdown under `.eca/issues/`. See
`.eca/docs/issue-tracker.md`.

### Triage labels

Triage uses the canonical role names. See
`.eca/docs/triage-labels.md`.

### Domain docs

Domain documentation uses a single-context layout. See
`.eca/docs/domain.md`.

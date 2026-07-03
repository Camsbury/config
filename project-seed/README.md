# project-seed (engine)

Minimal scaffolding engine: takes an EDN spec and renders a ready-to-run
project from the featureset at `$SHAREPATH/project-seed/`
(`~/Dropbox/lxndr` fallback). Everything project-shaped (templates, the
feature definitions and their docs, the file manifest, examples) is data
over there; this script only renders it and runs the setup steps. See
`$SHAREPATH/project-seed/README.md` for the featureset itself.

## Usage

```sh
bb new-project.bb --list                 # current features + examples
bb new-project.bb <spec.edn>             # path to a spec
bb new-project.bb minimal                # bare example name
bb new-project.bb '{:name "my-app"}'     # inline EDN
```

`--skip-nix` stops after files + git init + direnv allow (skips the lorri
build, dep upgrade, and prefetch); useful offline or when iterating on
templates.

## Engine-owned spec keys

Everything else in the spec passes straight through to the templates;
feature-specific keys are documented by `--list`.

- `:name` (required, kebab-case): project and namespace name.
- `:owner` (default `"Camsbury"`): project lands at
  `~/projects/<owner>/<name>`; this fixed depth is what the featureset's
  `../../dynamic-alpha` local-root deps rely on.
- `:description`: propagated to templates.
- `:features`: set validated against the featureset's `features.edn`;
  each selected feature turns on its flags in the render context.
- `:nixpkgs-rev`: override; the default is the system pin parsed from
  `nix-conf/system.nix`, so dev shells share store paths with the
  system. If neither is available the flake gets the plain `nixpkgs`
  registry ref (whatever nixpkgs means on the machine).

## What it does

1. Renders every `[template, target]` pair in the featureset's
   `manifest.edn` into `~/projects/<owner>/<name>` (target paths are
   selmer-rendered too), then `mkdir`s the plain dirs listed in the
   featureset's `dirs.edn` (e.g. `resources`, `data`).
2. `git init` + `git add -A` (flakes only see tracked files; no commit,
   you review and commit).
3. `direnv allow .`
4. `lorri watch --flake . --once` (builds the dev shell once so the
   `.envrc` eval is instant; no watcher left running).
5. `nix develop --command clojure -M:outdated --upgrade --force` (antq
   bumps seeded versions; best-effort, warns on failure).

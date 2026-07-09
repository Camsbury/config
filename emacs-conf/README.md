# My Emacs Config (cmacs)

This is **cmacs** - my personal Emacs configuration, which doubles as my desktop
environment via [EXWM](https://github.com/emacs-exwm/exwm) (the Emacs X Window
Manager). Dependencies are built with [Nix](https://nixos.org/nix/), and Emacs
is launched as the window manager itself rather than as an editor inside another
DE.

## My Emacs Philosophy
- Emacs is a manager and runner of blocks of text via text with some extra features
- Functions are more important than hotkeys -> you have the power to customize those yourself
- You must understand the basic vocabulary for [describing emacs](https://www.gnu.org/software/emacs/manual/html_node/emacs/index.html#Top)
- Be aware of
  - [Major Modes](https://www.gnu.org/software/emacs/manual/html_node/emacs/Major-Modes.html)
  - [Minor Modes](https://www.gnu.org/software/emacs/manual/html_node/emacs/Minor-Modes.html#Minor-Modes)
  - [M-x](https://www.gnu.org/software/emacs/manual/html_node/emacs/M_002dx.html), and of [how keys are described](https://www.gnu.org/software/emacs/manual/html_node/emacs/User-Input.html#User-Input)
  - The `describe` family of [commands](https://www.gnu.org/software/emacs/manual/html_node/emacs/Commands.html#Commands)
    - Useful to get descriptions for variables, functions, modes, fonts, etc.
  - The `messages` buffer (the `stdout` and `stderr` of emacs)
    - Useful for seeing any errors and logging that has occurred
  - [Command-log-mode](https://github.com/lewang/command-log-mode)
    - Used to log all commands that have been run (useful for following a series of events to later write into a function)
  - `info-emacs-manual`
    - The in-editor version of [The GNU Emacs Manual](https://www.gnu.org/software/emacs/manual/html_node/emacs/index.html)
  - Extremely useful tools
    - [evil-mode](https://github.com/emacs-evil/evil)
      - Pretending we are in vim for productivity's sake
    - [org-mode](https://orgmode.org/manual/) (built-in)
      - Probably the best organizational tool on the planet, with many cool features
    - [flycheck-mode](https://github.com/flycheck/flycheck)
      - How we get real time feedback in our code for compiler/checker errors and warnings
    - [vertico/consult/orderless/marginalia/embark](https://github.com/minad/vertico)
      - The completion + search stack; every picker goes through
        `completing-read` (Ivy was fully removed 2026-07)

## My Emacs Architecture

### Built and launched by Nix
The Emacs binary, all packages, and the launcher are produced by Nix. The
relevant expressions live in the sibling `nix-conf/` tree:

- `nix-conf/packages/emacs.nix` - the package manifest (an `emacsWithPackages`
  argument: melpa / elpa / elpa-devel / others lists).
- `nix-conf/derivations/cmacs/default.nix` - builds the `cmacs` launcher
  (`writeShellScriptBin`). It exports the environment (`CONFIG_PATH`,
  `EMACSLOADPATH`, `EMACS_C_SOURCE_PATH`, GSettings/XDG dirs) and runs Emacs
  with `--debug-init --no-site-file --no-site-lisp --no-init-file --load
  <this-dir>/init.el`. So this directory is loaded explicitly; there is
  **no** `~/.emacs.d` package management.
- `nix-conf/modules/exwm.nix` - makes EXWM the window manager: sets the system
  `EMACSLOADPATH`, selects `none+exwm` as the default session, and starts
  `cmacs` as the window-manager session.
- `nix-conf/modules/cmacs.nix` - entry module that wires the above into the
  system and installs `cmacs` + `cmacs-load-path`.

After a rebuild you can refresh the running `load-path` without restarting via
`M-x latest-loadpath` (see `config/env.el`), which shells out to the
`cmacs-load-path` helper.

### Environment the elisp expects
The launcher and the NixOS user environment provide these variables, consumed in
`core/env.el`:

| Var | Elisp | Meaning |
|-----|-------|---------|
| `CONFIG_PATH` | `cmacs-config-path` | this `emacs-conf` directory |
| `SHAREPATH` | `cmacs-share-path` | shared data (org-roam, books, summaries, sounds) |
| `USER_EMAIL` | `user-email` | |
| `USER_GPG_ID` | `user-gpg-id` | |
| `HOME` | `user-home-path` | |

### Minimal true dependencies
The config leans on a small set of foundational packages:

- [general](https://github.com/noctuid/general.el) - clean keybindings and mode hooks
- [use-package](https://github.com/jwiegley/use-package) - encapsulated package configuration
- [dash](https://github.com/magnars/dash.el) (plus `s`, `f`, `ht`) - functional elisp
- [hydra](https://github.com/abo-abo/hydra) - branching, context-aware keybinding menus

### Load order
`init.el` requires the layers in this order, then bootstraps EXWM workspaces:

```
init.el
  → init-options   ; bare UI, scrolling, backups, custom-file
  → prelude        ; libraries, Clojure-isms, the m-require macro
  → core           ; core/{desktop,env,text,bindings}
  → config         ; all feature modules
  → (create EXWM workspaces 0-9, switch to 1)
```

### Module system
Modules are namespaced features of the form `prefix/name` (e.g.
`config/langs/clj`), each ending in `(provide 'prefix/name)`. The `m-require`
macro (defined in `prelude.el`) pulls a list of them in by prefix:

```elisp
(m-require config
  performance transient-defaults
  theme search navigation env text prog info
  desktop dev langs modes services viewers games gtd)
```

The `lib/` layer is deliberately NOT in any `m-require` chain: those are pure
cross-cutting operations, pulled on demand with `(require 'lib/NAME)` (decision
0009, the library/application seam).

### File structure
- `init.el` - boot, GC tuning, EXWM workspace bootstrap
- `init-options.el` - bare UI/scroll/backup setup, `custom-file` redirect
- `prelude.el` - libraries, Clojure-isms (`comment`, `inc`, `dec`), `m-require`
- `core.el` / `config.el` - the two aggregators
- `core/` - foundational layer:
  - `bindings.el` - the command center: leader hydras, Evil bindings, super/meta swap
  - `keys-base.el` - foundational keybinding macro providers (evil + `general-evil-setup` + hydra), requirable so keybinding files expand their macros in isolation
  - `desktop.el` - EXWM proper: workspaces, global `s-*` keys, XF86 media keys
  - `env.el` - the `cmacs` customization group and env-var-backed settings
  - `text.el` - Evil + evil-collection
- `lib/` - library layer (decision 0009): pure cross-cutting operations, not
  boot-loaded, required on demand:
  - `utils.el` - grab-bag (uuid, file-to-string, delete-file-and-buffer,
    shuffle-selection, unescape-clipboard, minor-mode-active-p,
    set-window-width, lisp-eval-sexp-at-point, completing-read-in-order)
  - `shell.el` - shell-command ops (process spawns, background buffers,
    escaping, nix-shell command build)
  - `sound.el` - PipeWire audio-sink ops (reached from the `s-s` key via an
    autoload stub in `core/desktop.el`)
- `config/` - feature modules, grouped by area:
  - top-level: `theme`, `search`, `navigation`, `prog`, `info`, `text`
  - `desktop/` - app launchers, system/nix commands, browser links, windows
    (EXWM patches)
  - `dev/` - project, git, ediff, process, test
  - `langs/` - per-language setup (~26 languages; `clj.el` is the richest)
  - `services/` - lsp, eca, docker, email, feeds, irc, radio, spotify, tmux, notifications
  - `viewers/` - browser, epub, pdf, markdown, journal, files, vega
  - `modes/` - custom minor modes (blind, breeze, prettify; buffer centering
    and width-capping live inside prettify-mode)
  - `gtd.el` - org-roam GTD + pomodoro
  - `games/` - chess, wc3
  - `theme/` - EDN-sourced doom themes (`doom-molokam.edn` +
    `structural.edn`) and `editor.el`, which compiles the EDN to a
    `def-doom-theme` and live-applies it; boot loads the EDN
    authoritatively, the generated `.el` is a fallback
- `snippets/` - yasnippet trees per major mode
- `tools/` - dependency/seam tooling (not loaded by the config):
  `fc-check.sh` (per-file byte-compile harness), `cmacs-deps.el`
  (dependency analyzer/classifier), `lib-guard.sh` (lib/ must classify
  library), `wm-free-check.sh` (config must load without the WM)

External data (org-roam files, books, summaries, sounds) lives under `$SHAREPATH`
and is **not** part of this repo. Some commands also shell out to personal
scripts under `~/.scripts/` and to `manage_browser_links.clj` (Babashka).

### The leader / hydra system
Nearly all interaction flows through `hydra-leader`, bound to `SPC` in Evil
normal state and to `s-SPC` globally under EXWM. It branches into sub-hydras
(`hydra-spawn`, `hydra-nav`, `hydra-nixos`, `hydra-project`, `hydra-window`, …).
Per-mode menus hook in by remapping `empty-mode-leader` to the mode's own hydra
(e.g. `hydra-clj`, `hydra-eca`). Adding a feature usually means: write the
commands, define a mode hydra, and remap `empty-mode-leader` in that mode's map.

Note: Super and Meta are swapped (`x-super-keysym 'meta`, `x-meta-keysym
'super`), and EXWM simulation keys translate `s-c`→`C-c`, `s-v`→`C-v`, etc. for
X applications.

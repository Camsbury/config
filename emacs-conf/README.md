# My Emacs Config

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
    - [ivy/counsel/swiper](https://github.com/abo-abo/swiper/tree/8db9cc190127160741fe5afe036d86a3e911c0b9)
      - Searchability!

## My Emacs Architecture
- Nix to build dependencies
  - __../emacs.nix__ describes the packages to be built in a [nix](https://nixos.org/nix/) expression
  - These are then made available on the `$EMACSLOADPATH`
- Minimal true dependencies
  - [general](https://github.com/noctuid/general.el)
  Allows for clean bindings and mode hooks
  - [use-package](https://github.com/jwiegley/use-package)
  Allows for encapsulated package configuration
  - [dash](https://github.com/magnars/dash.el)
  Allows for functional elisp
  - [hydra](https://github.com/abo-abo/hydra)
  Allows for branching bindings that are smart about why and where they are used
- File Structure
  - [__init.el__](https://github.com/Camsbury/config/blob/master/cmacs/init.el)
  contains pre-configuration setup
  - [__config/config.el__](https://github.com/Camsbury/config/blob/master/cmacs/config/config.el)
  loads all my modules
  - [__config/__](https://github.com/Camsbury/config/blob/master/cmacs/config/)
  is the home of my modules
- Core Modules
  - [__config/functions-conf.el__](https://github.com/Camsbury/config/blob/master/cmacs/config/functions-conf.el)
  sets utility elisp functions
  - [__config/bindings-conf.el__](https://github.com/Camsbury/config/blob/master/cmacs/config/bindings-conf.el)
  sets bindings for commonly used functions
- Concessions
  - The modules aren't completely intuitive (will likely restructure soon)
    - Some are language based
    - Some are mode based
    - Some are utility based

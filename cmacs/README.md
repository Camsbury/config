# My Emacs Config

## My Emacs Philosophy
- Emacs is simply a text editing application with a decent programming language dedicated to it
- Functions are more important than hotkeys -> you can write one if you need one, then bind it to whatever
- You must understand the basic vocabulary for [describing emacs](https://www.gnu.org/software/emacs/manual/html_node/emacs/index.html#Top)
- Be aware of
  - [Major Modes](https://www.gnu.org/software/emacs/manual/html_node/emacs/Major-Modes.html)
  - [Minor Modes](https://www.gnu.org/software/emacs/manual/html_node/emacs/Minor-Modes.html#Minor-Modes)
  - [M-x](https://www.gnu.org/software/emacs/manual/html_node/emacs/M_002dx.html), and of [how keys are described](https://www.gnu.org/software/emacs/manual/html_node/emacs/User-Input.html#User-Input)
  - The `describe` family of [commands](https://www.gnu.org/software/emacs/manual/html_node/emacs/Commands.html#Commands)
  Useful to get descriptions for variables, functions, modes, fonts, etc.
  - The `messages` buffer (the `stdout` and `stderr` of emacs)
  Useful for seeing any errors and logging that has occurred
  - [Command-log-mode](https://github.com/lewang/command-log-mode)
  Used to log all commands that have been run (useful for following a series of events to later write into a function)

## My Emacs Architecture
- Nix to build dependencies
  - __../emacs.nix__ describes the packages to be built in a [nix]() expression
  - Most people will imperatively install these packages using [emacs commands](http://ergoemacs.org/emacs/emacs_package_system.html), or [use-package](https://github.com/jwiegley/use-package)
  - `(require '<package-name>)` to import!
- Minimal true dependencies
  - [general](https://github.com/noctuid/general.el)
  Allows for clean bindings and mode hooks
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

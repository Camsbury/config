let
  emacs  = import ./emacs.nix;
  darwin = import ./darwin.nix;
  linux  = import ./linux.nix;
  shared = import ./shared.nix;
  xps    = import ./xps.nix;
in
  shared ++ darwin ++ linux ++ [xps] ++ [emacs]

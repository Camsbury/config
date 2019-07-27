let
  emacs  = import ./emacs.nix;
  darwin = import ./darwin.nix;
  linux  = import ./linux.nix;
  shared = import ./shared.nix;
in
  shared ++ darwin ++ linux ++ [emacs]

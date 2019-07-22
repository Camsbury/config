{ pkgs }:

with pkgs; [
  ag
  bat
  exa
  fd
  gitAndTools.git-extras
  gitAndTools.hub
  # (haskell.packages.ghc865.ghcWithPackages (
  #   haskellPackages: with haskellPackages;
  #   [ Agda
  #     Cabal_2_4_1_0
  #     apply-refact
  #     ghcid
  #     hlint
  #   ]
  # ))
  htop
  httpie
  jq
  leiningen
  loc
  ripgrep
  rural
  shellcheck
  sloccount
  sourceHighlight
  sqlite
  tldr
  tmux
  tree
  wget
]

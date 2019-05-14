{ pkgs }:

with pkgs; [
  _1password
  ack
  ag
  audacity
  autojump
  # autorandr
  bat
  bear
  binutils
  cabal-install
  cabal2nix
  cargo
  carnix
  chromium
  curl
  dmenu
  docker
  docker_compose
  dropbox-cli
  emacs
  exa
  fd
  feh # wallpapers
  firefox
  fzf
  gcc
  gdb
  ghc
  gimp
  git
  gitAndTools.hub
  glibc
  gnumake
  gnupg
  gnutls
  haskellPackages.Agda
  haskellPackages.Cabal_2_4_1_0
  haskellPackages.apply-refact
  haskellPackages.ghcid
  haskellPackages.hlint
  haskellPackages.xmonad
  haskellPackages.xmonad-contrib
  haskellPackages.xmonad-extras
  htop
  httpie
  irony-server
  jq
  keychain
  libnotify
  man-pages
  nix-index
  notify-osd # to upgrade...
  oh-my-zsh
  openssh
  openssl
  peek
  pltScheme
  python36
  python36Packages.jedi
  python36Packages.jupyter_client
  python36Packages.jupyter_core
  python36Packages.pyls-isort
  python36Packages.pyls-mypy
  python36Packages.python-language-server
  python36Packages.yapf
  redshift
  ripgrep
  shellcheck
  slack
  sloccount
  slock
  sourceHighlight
  spotify # non-free
  sqlite
  stack2nix
  teensy-loader-cli
  tldr
  tmux
  tree
  udisks # manage drives
  unzip
  valgrind
  veracrypt
  vim
  vlc
  wget
  xclip # copy paste stuff
  xorg.xbacklight
  xorg.xmodmap
  xss-lock
  zip
  zsh
]

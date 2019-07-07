{ pkgs }:

with pkgs; [
  _1password
  ack
  anki
  ag
  audacity
  autojump
  # autorandr # maybe for displays?
  bat
  binutils
  brave
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
  gdb
  ghostscript # for viewing pdfs
  gimp
  git
  gitAndTools.hub
  glibc
  gnumake
  gnupg
  gnutls
  (haskell.packages.ghc865.ghcWithPackages (
    haskellPackages: with haskellPackages;
    [ Agda
      Cabal_2_4_1_0
      apply-refact
      ghcid
      hlint
    ]
  ))
  htop
  httpie
  irony-server
  jq
  keychain
  libnotify
  loc
  man-pages
  nix-index
  notify-osd # to upgrade...
  oh-my-zsh
  openssh
  openssl
  peek
  (python36.withPackages (
    pythonPackages: with pythonPackages;
      [ jedi
        jupyter_client
        jupyter_core
        isort
        mypy
        pyflakes
        pylint
        yapf
      ]
  ))
  redshift
  ripgrep
  shellcheck
  signal-desktop
  slack
  sloccount
  slock
  sourceHighlight
  spotify # non-free
  sqlite
  # stack2nix
  teensy-loader-cli # flash ergodox firmware (use zshrc alias for help)
  tldr
  tmux
  transmission
  tree
  typora
  udisks # manage drives
  unzip
  veracrypt
  vim
  vlc
  wget
  xclip # copy paste stuff
  xkb-switch
  xorg.xbacklight
  xorg.xmodmap
  xpdf
  xss-lock
  zip
  zsh
]

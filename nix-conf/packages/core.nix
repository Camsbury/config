{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    _1password
    ack
    ag
    anki
    audacity
    autojump
    bat
    beam.packages.erlangR22.elixir_1_9
    binutils
    brave
    chromium
    curl
    disper
    dmenu
    docker
    docker_compose
    dropbox-cli
    (emacsPackagesNg.emacsWithPackages (import ./emacs.nix))
    espeak # tts
    exa
    fd
    feh # wallpapers
    firefox
    fzf
    gdb
    ghostscript # for viewing pdfs
    gimp
    git
    gitAndTools.git-extras
    gitAndTools.hub
    glibc
    gnumake
    gnupg
    gnuplot
    gnutls
    google-cloud-sdk
    (haskell.packages.ghc864.ghcWithPackages (
      haskellPackages: with haskellPackages;
      [
      # Agda
        Cabal_2_4_1_0
        apply-refact
        ghcid
        hlint
      ]
    ))
    htop
    httpie
    inotify-tools
    # irony-server
    jq
    keybase
    keybase-gui
    keychain
    kubectl
    leiningen
    libnotify
    loc
    man-pages
    nix-index
    nodejs-11_x
    nodePackages.prettier
    notify-osd # to upgrade...
    oh-my-zsh
    openjdk
    openssh
    openssl
    openvpn
    peek
    postgresql_11
    (python36.withPackages (
      pythonPackages: with pythonPackages;
        [ isort
          jedi
          jupyter
          jupyter_core
          jupyter_client
          mypy
          pyflakes
          pylint
          yapf
        ]
    ))
    redshift
    ripgrep
    rural
    shellcheck
    signal-desktop
    slack
    sloccount
    slock
    sourceHighlight
    spotify # non-free
    sqlite
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
    yarn
    zip
    zsh
  ];
}

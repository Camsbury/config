{ pkgs }:

( with pkgs; if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then [
    _1password
    ack
    anki
    audacity
    autojump
    # autorandr # maybe for displays?
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
    espeak # tts
    feh # wallpapers
    firefox
    fzf
    gdb
    ghostscript # for viewing pdfs
    gimp
    git
    glibc
    gnumake
    gnupg
    gnuplot
    gnutls
    google-cloud-sdk
    inotify-tools
    irony-server
    keybase
    keybase-gui
    keychain
    libnotify
    man-pages
    nix-index
    nodejs-11_x
    notify-osd # to upgrade...
    oh-my-zsh
    openjdk
    openssh
    openssl
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
    signal-desktop
    slack
    slock
    spotify # non-free
    # stack2nix
    teensy-loader-cli # flash ergodox firmware (use zshrc alias for help)
    tmux
    transmission
    typora
    udisks # manage drives
    unzip
    veracrypt
    vim
    vlc
    xclip # copy paste stuff
    xkb-switch
    xorg.xbacklight
    xorg.xmodmap
    xpdf
    xss-lock
    yarn
    zip
    zsh
  ] else [])

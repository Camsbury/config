{ config, pkgs, ... }:

{

  nixpkgs.config.permittedInsecurePackages = [
    "xpdf-4.02"
  ];

  environment.systemPackages = with pkgs; [
    ack
    ag
    anki
    audacity
    autojump
    bat
    babashka
    binutils
    brave
    check-low-battery
    chromium
    cmacs
    curl
    direnv
    discord
    disper
    docker
    docker_compose
    dunst
    (emacsPackagesNg.emacsWithPackages (import ./emacs.nix))
    entr
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
    htop
    httpie
    inotify-tools
    jq
    keybase
    keybase-gui
    keychain
    killall
    kubectl
    libnotify
    loc
    lsof
    man-pages
    nix-index
    nixfmt
    nodePackages.prettier
    oh-my-zsh
    okular
    openssh
    openssl
    openvpn
    patchelf # patch dynamic libs/bins
    peek
    postgresql_11
    python3
    redshift
    ripgrep
    scid-vs-pc
    shellcheck
    signal-desktop
    slack
    sloccount
    sourceHighlight
    spotify # non-free
    sqlite
    tdesktop # telegram
    teensy-loader-cli # flash ergodox firmware (use zshrc alias for help)
    tldr
    transmission
    tree
    # typora # markdown
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
    zip
    zsh
  ];
}

# System packages contains all of the system-wide packages installed on my NixOS machines.

{ config, pkgs, ... }:

let
  unstableTarball = fetchTarball
    https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz;

  cachixBall = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/tarball/1d4de0d552ae9aa66a5b8dee5fb0650a4372d148") {};

  customPackages = import ./custom-packages.nix { inherit pkgs; };

  machine = import ./machine.nix;
in {
  nixpkgs.config = {
    allowUnfree = true;

    chromium = {
      enablePepperFlash = true;
    };

    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
    };
  };

  nixpkgs.overlays = import ./overlays.nix;

  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs"
    "nixpkgs-unstable=${unstableTarball}"
    "nixos-config=/etc/nixos/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;

  environment.systemPackages = with pkgs; [
    # Stable Packages
    _1password
    ack
    ag
    audacity
    autojump
    # autorandr
    bear
    binutils
    cabal-install
    cabal2nix
    cargo
    carnix
    curl
    dmenu
    docker
    docker_compose
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
    weechat
    wget
    xbindkeys
    xclip # copy paste stuff
    xorg.xbacklight
    xorg.xmodmap
    xss-lock
    zip
    zsh
  ] ++ [
    # Unstable Packages
    # unstable._1password
    unstable.bat
    unstable.chromium
    unstable.dropbox-cli
    # unstable.haskellPackages.Agda
    unstable.haskellPackages.Cabal_2_4_1_0
    unstable.haskellPackages.apply-refact
    unstable.haskellPackages.ghcid
    unstable.haskellPackages.hlint
    unstable.haskellPackages.xmonad
    unstable.haskellPackages.xmonad-contrib
    unstable.haskellPackages.xmonad-extras
    unstable.spotify # non-free
  ] ++ [
    # Custom Packages
    # (import ./emacs.nix { inherit pkgs; })
    (cachixBall.cachix)
    (import ./emacs.nix { pkgs = unstable; })
  ] ++ customPackages
    ++ (    # Machine Specific
  if machine.gaming
  then
  [ steam #non-free
  ] else []
  );

  security.wrappers.slock.source = "${pkgs.slock.out}/bin/slock";
}

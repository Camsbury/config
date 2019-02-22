# System packages contains all of the system-wide packages installed on my NixOS machines.

{ config, pkgs, ... }:

let
  unstableTarball = fetchTarball
    https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz;

  cachixBall = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/tarball/1d4de0d552ae9aa66a5b8dee5fb0650a4372d148") {};

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
    ack
    ag
    audacity
    autojump
    avrbinutils
    avrgcc
    avrlibc
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
    gimp
    git
    gitAndTools.hub
    glibc
    gnumake
    gnupg
    gnutls
    haskellPackages.Agda
    haskellPackages.Cabal_2_4_0_0
    haskellPackages.apply-refact
    haskellPackages.ghcid
    haskellPackages.hlint
    haskellPackages.xmonad
    haskellPackages.xmonad-contrib
    haskellPackages.xmonad-extras
    htop
    irony-server
    jq
    keychain
    libnotify
    man-pages
    notify-osd # to upgrade...
    oh-my-zsh
    openssh
    peek
    pltScheme
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
    unstable._1password
    unstable.bat
    unstable.chromium
    unstable.dropbox-cli
    unstable.ghc
    unstable.python36
    unstable.python36Packages.jedi
    unstable.python36Packages.pyls-isort
    unstable.python36Packages.pyls-mypy
    unstable.python36Packages.python-language-server
    unstable.python36Packages.yapf
    unstable.spotify # non-free
    ## unneeded because the config is passed into unstable!
    # (unstable.chromium.override { enablePepperFlash = true; })
  ] ++ [
    # Custom Packages
    # (import ./emacs.nix { inherit pkgs; })
    (cachixBall.cachix)
    (import ./emacs.nix { pkgs = unstable; })
  ] ++ (    # Machine Specific
  if machine.gaming
  then
  [ steam #non-free
  ] else []
  );

  security.wrappers.slock.source = "${pkgs.slock.out}/bin/slock";
}

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
      enablePepperPDF = true;
    };

    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
    };
  };

  virtualisation.docker.enable = true;
  virtualization.docker.enableOnBoot = true;

  environment.systemPackages = with pkgs; [
    # Stable Packages
    ack
    ag
    autojump
    # autorandr
    bear
    cabal-install
    cabal2nix
    cargo
    carnix
    curl
    docker
    docker_compose
    dmenu
    exa
    fd
    firefox
    fzf
    gcc
    gdb
    ghc
    git
    gitAndTools.hub
    gnumake
    gnutls
    haskellPackages.apply-refact
    haskellPackages.Agda
    haskellPackages.Cabal_2_2_0_0
    haskellPackages.hlint
    haskellPackages.xmonad
    haskellPackages.xmonad-contrib
    haskellPackages.xmonad-extras
    htop
    irony-server
    libnotify
    man-pages
    notify-osd # to upgrade...
    nox
    oh-my-zsh
    openssh
    peek
    python3
    redshift
    ripgrep
    shellcheck
    slack
    slock
    sqlite
    teensy-loader-cli
    tldr
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
    zsh
  ] ++ [
    # Unstable Packages
    unstable._1password
    unstable.bat
    unstable.dropbox-cli
    unstable.spotify # non-free
    unstable.chromium
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
